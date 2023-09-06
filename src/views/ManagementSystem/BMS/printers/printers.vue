<template>
  <div class="card-min-group">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="showDrawerHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="showDrawerHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="btn_in_vain.png" colors="transparent"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="btn_effective.png" colors="transparent"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <characters-button @click.native="detectionHandle" colors="transparent" wz='检测'></characters-button>
      <characters-button @click.native="printTestHandle" colors="transparent" wz='打印测试'></characters-button>
    </div>

    <!-- table -->
    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">
              <el-checkbox
                v-model="checked"
                :indeterminate="indeterminate"
                @change="changeCheckboxHandle('all')"
              >序号</el-checkbox>
            </div>
            <div class="th">打印机名称</div>
            <div class="th">IP地址</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">状态</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked,'gray': item.s == '无效'}"
            v-for="(item,index) in tableData"
            :key="index"
            layout="row"
            layout-align="start center"
          >
            <div class="td">
              <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{index+1}}</el-checkbox>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.i}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <drawerAddOrUpdatePrinter
      v-model="showDrawer"
      :type="type"
      :currentInfo="currentInfo"
      @getTableData="getTableData"
    />

    <!-- 置为有效无效删除冲突 -->
    <drawerNextDrawer v-model="showNextDrawer" :effectType="effectType" :nexDrawerInfo="nexDrawerInfo"  @getTableData="getTableData" @setEffectOrNotEffect="setEffectOrNotEffect" />
  </div>
</template>
 
<script>
import IconButton from "@/components/IconButton.vue";
import CharactersButton from '@/components/CharactersButton.vue'
export default {
  data() {
    return {
      checked: false,
      indeterminate: false,
      type: 1,
      tableData: [],
      showDrawer: false,
      currentInfo: {},

      effectType: 1, // 1无效  2有效 3删除
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      nexDrawerInfo: {
        ns: [],
        cs: []
      }
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.printer.requestprinterlist()
        if (res.code == 1) {
          this.tableData = (res.data || []).map(item => ({
            ...item,
            checked: false
          }));
          this.indeterminate = this.checked = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },
    
    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checked;
          });
          this.indeterminate = false;
          break;
        case "item":
          this.checked = this.tableData.every(item => item.checked);
          this.indeterminate =
            !this.checked && this.tableData.some(item => item.checked);
          break;
      }
    },

    showDrawerHandle(type) {
      if (type == 2) {
        const checkedList = this.tableData.filter(item => item.checked);
        if (checkedList.length > 1 || checkedList.length == 0) {
          return this.$message.warning("请选择一个操作");
        }
        this.currentInfo = checkedList[0];
      } else if (type == 1) {
        this.currentInfo = {};
      }
      this.type = type

      this.showDrawer = true;
    },

    async setEffectOrNotEffect(type) {
      // type : 1：无效  2：有效  3：删除
      this.effectType = type
      const checkedList = this.tableData.filter(item => item.checked);
      if (checkedList.length == 0) {
        return this.$message.warning("请选择一个进行操作");
      }
      const params = {
        ids: checkedList.map(item => item.id * 1) //   []int64  请求id数组
      };
      try {
        const api = type == 1 ? 'requestprinterdisable' : (type == 2 ? 'requestprinterenable' : 'requestprinterdel')
        const res = await this.$api.BMS.printer[api](params);
        if(res.code == 1) {
          this.getTableData()
          this.$message.success('操作成功')
        } else if(res.code == 2) {
          this.showNextDrawer = true
          this.nexDrawerInfo.ns = res.data.ns || []
          this.nexDrawerInfo.cs = (res.data.cs || []).map(item => ({
            ...item,
            jg: '---'
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("设置有效无效删除失败", error);
      }
    },

    
    // 检测
    async detectionHandle(){
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length != 1) return this.$message.warning('请选择一个进行检测')

      const params = {
        id: checkedList[0].id * 1
      }
      try {
        const res = await this.$api.BMS.printer.requestprinterchk(params)
        if(res.code == 1) {
          this.$message.success('打印机连接正常')
        } else if (res.code == 26) {
          this.$message.warning('打印机连接出现故障！请修复故障后再重新检测！')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('打印检测失败', error);
      } 
    },

    // 测试打印
    async printTestHandle(){
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length != 1) return this.$message.warning('请选择一个打印机测试')
      const params = {
        id: checkedList[0].id * 1  // int64    请求id
      }
      try {
        const res = await this.$api.BMS.printer.requestprinterprt(params)
        res.code == 1 ? this.$message.success('打印测试成功') : this.$message.warning(res.msg);
      } catch (error) {
        console.log('打印测试失败', error);
      }
    },
  },
  created() {
    this.getTableData();
  },
  components: {
    IconButton,
    CharactersButton,
    drawerAddOrUpdatePrinter: () => import('./drawerAddOrUpdatePrinters.vue'),
    drawerNextDrawer: () => import('./drawerNextDrawer.vue')
  },
  filters: {}
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style lang="less" scoped>
.card-min-group {
  padding: 20px;

  .top {
    background-color: #eee;
  }

  .table {
    .th,.td {
      &:nth-child(1) ,
      &:nth-child(6) {
        width: 30%;
      }
      &:nth-child(2) {
        width: 70%;
      }
    }
  }
}
</style>