<template>
  <div class="wine-info">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="showDrawerHandle" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="deleteHandle" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <characters-button @click.native="showDrawerOfPassTime" colors="transparent" wz='批量设置有效期'></characters-button>
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
            <div class="th">商品名称</div>
            <div class="th">一级分类</div>
            <div class="th">二级分类</div>
            <div class="th">整瓶有效期</div>
            <div class="th">散瓶有效期</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked}"
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
            <div class="td">{{item.f}}</div>
            <div class="td">{{item.l}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
    <drawerAddWine
      :showDrawer="showDrawer"
      @showDrawerHandle="showDrawerHandle"
      @getTableData="getTableData"
    />
    <drawerPassTime
      :showDrawer="showPassTimeDrawer"
      :ids="ids"
      @showDrawerHandle="showDrawerOfPassTime"
      @getTableData="getTableData"
    />
  </div>
</template>
 
<script>
import IconButton from "@/components/IconButton.vue";
import CharactersButton from '@/components/CharactersButton.vue'
import drawerAddWine from "./drawerAddWineCom/drawerAddWineCom.vue";
import drawerPassTime from "./drawerAddWineCom/drawerPassTimeCom.vue";
export default {
  data() {
    return {
      checked: false,
      indeterminate: false,
      tableData: [],
      showDrawer: false,
      showPassTimeDrawer: false,
      dataInfo: {}
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.saveWine.reqGetWineList();
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
        console.log("存酒列表数据获取失败", error);
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
    showDrawerHandle() {
      this.showDrawer = !this.showDrawer;
    },

    showDrawerOfPassTime(){
      if(!this.showPassTimeDrawer && this.ids.length == 0) return this.$message.warning('请选择商品')
      this.showPassTimeDrawer = !this.showPassTimeDrawer
    },

    async deleteHandle() {
      if (this.ids.length == 0) {
        return this.$message.warning("请选择需要删除的理由");
      }
      const params = {
        prd_ids: this.ids //   []int64  请求id数组
      };
      try {
        const res = await this.$api.BMS.saveWine.reqDelWine(params);
        if (res.code == 1) {
          this.$message.success("删除成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除失败", error);
      }
    }
  },
  created() {
    this.getTableData()
  },
  components: {
    IconButton,
    CharactersButton,
    drawerAddWine,
    drawerPassTime
  },
  computed: {
    ids(){
      return this.tableData.filter(item => item.checked).map(item => item.id * 1)
    }
  }
};
</script>

<style lang="less" scoped>
@import "./wineInfo.less";
@import "../../../../../style/erp/table.less";
</style>