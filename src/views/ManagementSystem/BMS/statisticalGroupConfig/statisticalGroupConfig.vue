<template>
  <div class="sta-container">
    <div class="top" layout="row" layout-align="start center">
      <p class="red">说明：请重新划分商品分类，在收银系统将根据新配置的统计类别汇总各渠道类别收入</p>
    </div>

    <div class="m-t-3">
      <el-button type="primary" size="small" @click="showOrHideDrawerHandle">新增类别</el-button>
      <el-button size="small" type="primary" @click="deleteHandle">批量删除</el-button>
      <el-button size="small" type="primary" @click="deleteHandle">调整顺序</el-button>
    </div>

    <!-- table -->
    <div class="table-content m-t-2"> 
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
            <div class="th">统计类别名称</div>
            <div class="th">类型</div>
            <div class="th">包含二级分类/商品</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">操作</div>
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
            <div class="td">{{item.on}}</div>
            <div class="td">{{item.tn}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.pt}}</div>
            <div class="td">{{item.pt}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <drawerAddPrdCom
      :showDrawer="showDrawer"
      :addedSeatList="tableData"
      @showOrHideDrawerHandle="showOrHideDrawerHandle"
      @getTableData="getTableData"
    />
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      keyword: '',
      checked: false,
      indeterminate: false,
      tableData: [],
      showDrawer: false,
      currentInfo: {}
    };
  },
  methods: {
    async getTableData() {
      const params = {
        key: this.keyword || ''  //  string  模糊查询关键字
      }
      try {
        const res = await this.$api.BMS.miniProgressConfig.reqGetMiniConfig(params)
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
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
    changeCheckboxHandle(type){
      switch(type) {
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
    async deleteHandle(){
      const params = {
        ids: this.tableData.filter(item => item.checked).map(item => item.id * 1), //        []int64      //PrdIds 待添加的商品Id列表
      }
      if(params.ids.length <= 0) return this.$message.warning('请选择需要删除的商品')
      try {
        const res = await this.$api.BMS.miniProgressConfig.reqDelMiniData(params)
        if(res.code == 1) {
          this.$message.success('删除成功')
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    showOrHideDrawerHandle(){
      this.showDrawer = !this.showDrawer
    },
    resetHandle(){
      this.keyword = ''
      this.getTableData()
    }
  },
  created() {
    this.resetHandle();
  },
  components: {
    drawerAddPrdCom: () => import('./drawerAddPrdCom/drawerAddPrdCom.vue')
  },
  filters: {}
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style lang="less" scoped>
.sta-container {
  padding: 20px;

  .red {
    color: red;
  }

  .table {
    max-height: calc(100vh - 240px);
    overflow: auto;
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