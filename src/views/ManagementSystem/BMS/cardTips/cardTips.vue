<template>
  <div class="card-tips">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="showDrawerHandle('add')" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="showDrawerHandle('edit')" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="deleteHandle" text="批量删除" img="btn_delete.png" colors="#6B2830"
      ></icon-button>
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
            <div class="th">标签名称</div>
            <div class="th">显示标记</div>
            <div class="th">更新时间</div>
            <div class="th">创建时间</div>
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
            <div class="td">{{item.r}}</div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
    <addOrUpdateCardTips
      :show="showDrawer"
      :dataInfo="dataInfo"
      @showDrawerHandle="showDrawerHandle"
      @getTableData="getTableData"
    />
  </div>
</template>
 
<script>
import IconButton from "@/components/IconButton.vue";
import addOrUpdateCardTips from "./drawerAddOrUpdateCardTips.vue";
export default {
  data() {
    return {
      checked: false,
      indeterminate: false,
      tableData: [],
      showDrawer: false,
      dataInfo: {}
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.cardTips.getCardTips();
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
        console.log("卡台标签获取失败", error);
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
      if (type == "edit") {
        const checkedList = this.tableData.filter(item => item.checked);
        if (checkedList.length > 1 || checkedList.length == 0) {
          return this.$message.warning("请选择一个操作");
        }
        this.dataInfo = checkedList[0];
      } else if (type == "add") {
        this.dataInfo = {};
      }

      this.showDrawer = !this.showDrawer;
    },
    async deleteHandle() {
      const checkedList = this.tableData.filter(item => item.checked);
      if (checkedList.length == 0) {
        return this.$message.warning("请选择需要删除的标签");
      }
      const params = {
        ids: checkedList.map(item => item.id * 1) //   []int64  请求id数组
      };
      try {
        const res = await this.$api.BMS.cardTips.delCardTips(params);
        if (res.code == 1) {
          this.$message.success("删除成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除标签失败", error);
      }
    }
  },
  created() {
    this.getTableData();
  },
  components: {
    IconButton,
    addOrUpdateCardTips
  },
  filters: {}
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
@import "./cardTips.less";
</style>