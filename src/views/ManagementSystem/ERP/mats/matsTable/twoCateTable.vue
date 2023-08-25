<template>
  <div class="second-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdateErpLibHandle(1)" text="新增" img="添加.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateErpLibHandle(2)" text="编辑" img="编辑.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="无效.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="有效.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="删除.png" colors="#6B2830"></icon-button>
    </div>
    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">二级分类名称</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">状态</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked,'gray': item.s == '无效'}"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
              </div>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 新增或编辑 -->
        <drawerAddOrUpdateTwoCate v-model="showDrawer" :currentInfo="currentInfo" :type="type" :menuList="menuList" @getTableData="getTableData" />
        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :nexDrawerInfo="nexDrawerInfo" :effectType="effectType" @getTableData="getTableData" @setEffectOrNotEffect="setEffectOrNotEffect" />
      </div>
    </div>
  </div>
</template>
 
<script>
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import drawerAddOrUpdateTwoCate from './twoCateTableCom/drawerAddOrUpdateTwoCate.vue'
import drawerNextDrawer from './twoCateTableCom/drawerNextDrawer.vue'
export default {
  data() {
    return {
      tableData: [],
      checkAll: false,
      type: 1, // 1:新增  2：修改
      effectType: 1, // 1:无效  2：有效  3：删除
      currentInfo: {}, // 当前修改的数据
      showDrawer: false,
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      nexDrawerInfo: {
        ns: [],
        cs: []
      }
    };
  },
  methods: {
    async getTableData() {
      const params = {
        id: this.$route.query.menuId * 1 || 0
      }
      try {
        const res = await this.$api.ERP.mtcate.requestmtcatelist(params);
        if (res.code == 1) {
          this.tableData = (res.data || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checkAll = false;
          this.$emit('getMenuList')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    // 新增或修改
    addOrUpdateErpLibHandle(type) {
      const checkedList = this.tableData.filter(item => item.checked)
      if(type == 2) {
        if(checkedList.length == 1) {
          this.currentInfo = checkedList[0]
        } else {
          return this.$message.warning('请选择一条数据进行操作')
        }
      }
      this.showDrawer = true
      this.type = type
    },

    // 设为有效或无效或删除
    async setEffectOrNotEffect(type){
      // type : 1无效  2有效 3删除
      this.effectType = type
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length <= 0) return this.$message.warning('请选择一个进行操作')
      const params = {
        ids: checkedList.map(item => item.id * 1)
      }
      try {
        const api = type == 1 ? 'requestmtcatedisable' : (type == 2 ? 'requestmtcateenable' : 'requestmtcatedel')
        const res = await this.$api.ERP.mtcate[api](params)
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
        console.log('设置有效无效失败', error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
    }
  },
  created() {
    this.getTableData();
  },
  props: {
    menuList: {
      default: () => ([])
    }
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  components: {
    EllipsisTooltip,
    IconButton,
    drawerAddOrUpdateTwoCate,
    drawerNextDrawer
  },
  watch: {
    '$route': {
      handler() {
        this.getTableData()
      }
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.second-table {
  padding: 20px;
  .top {
    background-color: #eee;
  }
  .table-content {
    .table {
      max-height: calc(100vh - 160px);
      overflow: auto;
      .th,.td{
        &:nth-child(1),
        &:nth-child(5){
          width: 30%;
        }
        &:nth-child(2){
          width: 70%;
        }
      }
    }
  }
}
</style>