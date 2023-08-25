<template>
  <div class="card-min-group">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="showDrawerHandle(1)" text="新增" img="添加.png" colors="#383943"></icon-button>
      <icon-button @click.native="showDrawerHandle(2)" text="编辑" img="编辑.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="无效.png" colors="transparent"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="有效.png" colors="transparent"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="删除.png" colors="#6B2830"></icon-button>
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
            <div class="th">出品库名称</div>
            <div class="th">存货仓库名称</div>
            <div class="th">出品打印机名称</div>
            <div class="th">出品打印次数</div>
            <div class="th">传菜打印名称</div>
            <div class="th">传菜打印次数</div>
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
            <div class="td">{{item.sn}}</div>
            <div class="td">{{item.pn}}</div>
            <div class="td">{{item.pc}}</div>
            <div class="td">{{item.cn}}</div>
            <div class="td">{{item.cc}}</div>
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

    <drawerAddOrUpdateOutLibConfig
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
        const res = await this.$api.BMS.mklib.requestmkliblist()
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
        const api = type == 1 ? 'requestmklibdisable' : (type == 2 ? 'requestmklibenable' : 'requestmklibdel')
        const res = await this.$api.BMS.mklib[api](params);
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
    }
  },
  created() {
    this.getTableData();
  },
  components: {
    IconButton,
    drawerAddOrUpdateOutLibConfig: () => import('./drawerAddOrUpdateOutLibConfig.vue'),
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

  .table-content {
    width: 100%;
    max-height: calc(100vh - 180px);
    overflow: auto;
    .table {
      min-width: 1600px;
      .thead {
        .th {
          background-color: #f5f5f5;
        }
      }
      .tbody {
        .tr{
          &:nth-child(2n) {
            .td {
              background-color: #f5f5f5;
            }
          }
          &:nth-child(2n + 1) {
            .td {
              background-color: #f9f9f9;
            }
          }
        }
      }
      .th,.td {
        &:nth-child(5) ,
        &:nth-child(6) ,
        &:nth-child(7) ,
        &:nth-child(10) {
          width: 40%;
        }
        &:nth-child(2) {
          width: 70%;
        }

        
         &:nth-child(1){
          width: 30%;
          position: sticky;
          left: 0;
         }
         &:nth-child(2){
          position: sticky;
          left: 107px;
         }
      }
    }
  }
  
}
</style>