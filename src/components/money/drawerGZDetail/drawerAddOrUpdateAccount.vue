<template>
  <div>
    <!-- 新增或修改挂账账户 -->
    <el-drawer
      :title="currentInfo.id ? '修改账户' : '新增账户'"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="600px"
    >
      <div class="add-or-update-account">
        <div class="form">
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>账户名称:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <input type="text" v-model="account" placeholder="请输入账户名称（1-30字）" />
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>联系人:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <input type="text" v-model="userName" placeholder="请输入联系人（1-30字）" />
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>联系方式:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <input type="text" v-model="phoneNum" placeholder="请输入联系方式" />
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
export default {
  data() {
    return {
      show: false,
      account: "",
      userName: "",
      phoneNum: ""
    };
  },
  methods: {
    init() {
      console.log(this.currentInfo)
        this.account = this.currentInfo.id ? this.currentInfo.n : ''
        this.userName = this.currentInfo.id ? this.currentInfo.cn : ''
        this.phoneNum = this.currentInfo.id ? this.currentInfo.cp : ''
    },
    // 提交
    async onSubmit() {
      const params = {
        name: this.account, //       string     //Name 挂账账户名称
        contact_name: this.userName, // string     //ContactName 联系人姓名
        contact_phone: this.phoneNum, // string     //ContactPhone 联系人手机
        ...(this.currentInfo.id && { id: this.currentInfo.id * 1 })
      };
      if(!params.name) return this.$message.warning('请输入挂账账户名称')
      if(params.contact_phone && params.contact_phone.length != 11) return this.$message.warning('请输入正确的11位手机号码')
      try {
        const api = this.currentInfo.id
          ? "reqUpdateGZInfo"
          : "reqAddGZInfo";
        const res = await api_money[api](params);
        if (res.code == 1) {
          this.$message.success(!this.currentInfo.id ? "添加成功" : '修改成功');
          this.$emit("getTableData");
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log(!this.currentInfo.id ? "添加挂账账户失败" : '修改挂账账户失败', error);
      }
    },
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    currentInfo: {
      default: () => ({})
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.init();
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>
.add-or-update-account {
  padding: 20px;
  color: rgba(255, 255, 255, 8);
  font-size: 14px;

  .red {
    color: #ff2f64;
  }

  .form {
    .row {
      padding: 10px 20px;
      .label {
        width: 100px;
        text-align: right;
      }
      .value {
        padding-left: 10px;
        input {
          padding: 0 10px;
          box-sizing: border-box;
          width: 200px;
          height: 30px;
          border-radius: 8px;
          box-sizing: border-box;
          border: 1px solid rgba(255, 255, 255, 0.15);
        }

        .btn {
          margin-left: 10px;
          background-color: #4b89ff;
          border-radius: 4px;
          width: 90px;
          height: 30px;
          line-height: 30px;
          text-align: center;
          cursor: pointer;

          &.disabled {
            background-color: #aaa;
            color: #eee;
            cursor: no-drop;
          }
        }
      }
    }
  }
}
</style>