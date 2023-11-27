<template>
  <div>
    <!-- 挂账详情 -->
    <el-drawer
      title="挂账详情"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="GZ-detail">
        <div class="top" layout="row" layout-align="start center">
          <div class="btn" @click="showOrHideDrawer($event,'add')" layout="row" layout-align="center center">
            <img :src="require('../../../assets/money-img/money_add.png')" alt="">
            <div class="tips">新增</div>
          </div>
          <div class="btn" @click="showOrHideDrawer($event,'edit')" layout="row" layout-align="center center">
            <img :src="require('../../../assets/money-img/edit.png')" alt="">
            <div class="tips">编辑</div>
          </div>
          <div class="btn" @click="deleteHandle" layout="row" layout-align="center center">
            <img :src="require('../../../assets/money-img/del.png')" alt="">
            <div class="tips">删除</div>
          </div>

          <div layout="row" layout-align="center center">
            <input style="width: 150px; height: 25px; line-height: 20px; padding: 3px 10px" v-model="keyword" placeholder="账户名称" />
            <el-button
              class="m-l-4"
              type="primary"
              style="width: 70px; height: 30px; line-height: 30px; padding: 0"
              @click="getTableData"
              >查询</el-button
            >
          </div>
        </div>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">
                <el-checkbox
                  :indeterminate="indeterminate"
                  v-model="checkAll"
                  @change="changeCheckBoxHandle('all')"
                >全选</el-checkbox>
              </div>
              <div class="th">账户名称</div>
              <div class="th">联系人</div>
              <div class="th">联系方式</div>
              <div class="th">剩余挂账金额</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item, index) in tableData"
              :key="index"
            >
              <div class="td">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckBoxHandle('item')"
                >{{index + 1}}</el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.cn}}</div>
              <div class="td">{{item.cp}}</div>
              <div class="td">{{item.a}}</div>
              <div class="td">
                <span :class="{disabled: item.a * 1 <= 0}" @click="showOrHideGaveMoneyDrawer($event, item)">挂账还款</span>
                <span  @click="showOrHideDetailDrawer($event, item)">查看记录</span>
              </div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
          </div>
        </div>
        <addOrUpdateAccount :showDrawer="showOrHideAddCount" :currentInfo="currentInfo" @getTableData="getTableData" @showOrHideDrawer="showOrHideDrawer" />

        <gaveMoney :showDrawer="showOrHideGaveMoney" :currentInfo="currentInfo" @getTableData="getTableData" @showOrHideGaveMoneyDrawer="showOrHideGaveMoneyDrawer" />

        <accountDetail :showDrawer="showOrHideDetail" :currentInfo="currentInfo" @showOrHideDetailDrawer="showOrHideDetailDrawer" />
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import addOrUpdateAccount from './drawerAddOrUpdateAccount.vue'
import accountDetail from './drawerAccountDetail.vue'
// 挂账还款
import gaveMoney from './drawerGaveMoney.vue'
export default {
  data() {
    return {
      show: false,
      checkAll: false,
      showOrHideAddCount: false,
      showOrHideGaveMoney: false,
      showOrHideDetail: false,
      currentInfo: {},
      tableData: [],
      keyword: '',
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      try {
        const res = await api_money.reqGetGZList({key: this.keyword});
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false
          }))
          this.checkAll = false
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },

    changeCheckBoxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }));
          break;

        case "item":
          this.checkAll = this.tableData.every(item => item.checked)
          break;
      }
    },

    showOrHideDrawer(e, type){
      if(type && type == 'edit') {
        const checkedInfo = this.tableData.filter(item => item.checked)
        if(checkedInfo.length != 1) return this.$message.warning('请选择一个进行操作')
        this.currentInfo = checkedInfo[0]
      }
      this.showOrHideAddCount = !this.showOrHideAddCount

      if(!this.showOrHideAddCount) {
        this.currentInfo = {}
      }
    },

    async deleteHandle(){
      const checkedInfo = this.tableData.filter(item => item.checked)
      if(checkedInfo.length != 1) return this.$message.warning('请选择一个进行删除操作')
      if(checkedInfo[0].a * 1 > 0) return this.$message.warning('当前账户挂账金额大于0，不可删除') 
      const params = {
        id : checkedInfo[0].id* 1 //    int64   挂账账户Id
      }
      try {
        const res = await api_money.reqDeleteGZInfo(params);
        if (res.code == 1) {
          this.$message.success('删除成功')
          this.getTableData()
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除挂账账户失败", error);
      }
    },

    showOrHideGaveMoneyDrawer(e, itemInfo = {}){
      if(itemInfo.id && itemInfo.n && itemInfo.a * 1 == 0) return
      this.currentInfo = itemInfo
      this.showOrHideGaveMoney = !this.showOrHideGaveMoney
    },

    showOrHideDetailDrawer(e, itemInfo = {}){
      this.currentInfo = itemInfo
      this.showOrHideDetail = !this.showOrHideDetail
    },

    onCancelDrawer() {
      this.$emit("showOrHideGZDetailDrawer");
    },
    keyHandle(event){
    // 回车按钮触发getTableData
      if (event.keyCode === 13) {
        this.getTableData();
      }
    }
  },
  mounted() {
    setTimeout(() => {
      // 给document绑定onkeydown事件
      document.onkeydown = this.keyHandle;
    })

    
  },
  // 页面销毁时解绑onkeydown事件
  beforeDestroy() {
    // Unbind onkeydown event from document
    document.onkeydown = null;
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  computed: {
    indeterminate(){
      return !this.checkAll && this.tableData.some(item => item.checked)
    }
  },
  components: {
    addOrUpdateAccount,
    gaveMoney,
    accountDetail
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      this.keyword = "";
      newVal ? this.getTableData() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/money/drawerGZDetail/index.less";
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>