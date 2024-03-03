<template>
  <div class="vip vip-online">
    <div class="top" v-if="$store.getters.vipAuth" layout="row" layout-align="start center">
      <icon-button
        @click.native="showDrawerHandle('add')"
        text="新增"
        img="btn_add.png"
        bjcolors="#DDE0E9"
        bcolor="#8c8c8c"
      ></icon-button>
      <icon-button
        @click.native="showDrawerHandle('edit')"
        text="编辑"
        img="btn_edit.png"
        bjcolors="#DDE0E9"
        bcolor="#8c8c8c"
      ></icon-button>
    </div>

    <!-- table -->
    <div class="table">
      <div class="thead">
        <div class="tr" layout="row" layout-align="start center">
          <div class="th">
            <el-checkbox
              v-if="$store.getters.vipAuth"
              v-model="checked"
              :indeterminate="indeterminate"
              @change="changeCheckboxHandle('all')"
            >序号</el-checkbox>
            <span v-else style="color:#1A1A21">序号</span>
          </div>
          <div class="th">充值金额</div>
          <div class="th">赠送金额</div>
          <div class="th">赠送卡券</div>
          <div class="th">赠送积分</div>
          <div class="th" v-if="$store.getters.vipAuth">操作</div>
        </div>
      </div>
      <div class="tbody">
        <div
          class="tr"
          :class="{'checked': item.checked}"
          v-for="(item,index) in tableData"
          :key="index"
          layout="row"
          layout-align="start center"
        >
          <div class="td">
            <el-checkbox v-if="$store.getters.vipAuth" v-model="item.checked" @change="changeCheckboxHandle('item')">{{index+1}}</el-checkbox>
            <span v-else style="color:#1A1A21">{{index + 1}}</span>
          </div>
          <div class="td fs16-bold">{{item.d}}</div>
          <div class="td fs16-bold">{{item.f}}</div>
          <div class="td fs16-bold">{{item.fk}}</div>
          <div class="td fs16-bold">{{item.fp}}</div>
          <div class="td" v-if="$store.getters.vipAuth"><span @click="delItemInfo(item)">删除</span></div>
        </div>
        <div class="no-data" v-if="tableData.length==0">
          <img :src="require('@/assets/vip-imgs/empty.png')" alt />
          <p>暂无数据</p>
        </div>
      </div>
    </div>
    <drawerAddOrUpdateMakeMoneyToVip
      :showDrawer="showDrawer"
      :editInfo="editInfo"
      @showOrHideHandle="showDrawerHandle"
      @getTableData="getTableData"
    />
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
import IconButton from "@/components/IconButton.vue";
import drawerAddOrUpdateMakeMoneyToVip from "@/components/vip/onlineMakeMoney/drawerAddOrUpdateMakeMoneyToVip.vue";
export default {
  data() {
    return {
      checked: false,
      indeterminate: false,
      tableData: [],
      showDrawer: false,
      editInfo: {},
    };
  },
  props: {
    item: {
      type: Object,
      default: () => ({})
    }
  },
  watch: {
    item: {
      handler(newVal) {
        this.getTableData();
      },
      immediate: true,
    },
  },
  methods: {
    async getTableData() {
      try {
        const res = await api_vip.reqGetVipCardMakeMoneyListRule({
          card_type_id: this.item.id
        });
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
        console.log("线上充值列表获取失败", error);
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
        this.editInfo = checkedList[0];
      } else if (type == "add") {
        this.editInfo = {};
      }

      this.showDrawer = !this.showDrawer;
    },

    async delItemInfo(itemInfo) {
      const params = {
        deposit_amt: itemInfo.d * 1,  // int    充值金额
        free_amt: itemInfo.f * 1,  //   int    赠送金额, 用于删除的二次判断
      };
      try {
        const res = await api_vip.reqDelVipCardMakeMoneyRule(params);
        if (res.code == 1) {
          this.$message.success("删除成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除充值规则失败", error);
      }
    }
  },
  created() {
    this.getTableData();
  },
  components: {
    IconButton,
    drawerAddOrUpdateMakeMoneyToVip
  },
  filters: {}
};
</script>

<style lang="less" scoped>
@import "../../../style/vip/vip.less";
</style>
<style lang="less" scoped>
.vip-online {
  .table {
    max-height: calc(100vh - 250px);
    overflow-y: auto;
    .tr {
      .th,
      .td {
        width: 30%;
      }
      .th:nth-child(1),
      .td:nth-child(1),
      .th:nth-last-child(1),
      .td:nth-last-child(1) {
        width: 20%;
        span{
          color: #2362D5;
          cursor: pointer;
        }
      }
    }
  }
}
</style>