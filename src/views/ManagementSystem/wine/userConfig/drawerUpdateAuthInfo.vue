<template>
  <div>
    <!-- 修改客户信息 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="600px"
    >
      <div class="session p-5">
        <!-- 修改姓名 -->
        <div v-if="status==1">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>用户姓名:</span>
            </div>
            <div class="value">
              <el-input
                v-model="userName"
                size="small"
                :maxLength="10"
                placeholder="1-10个字"
                style="width:200px"
              ></el-input>
            </div>
          </div>
        </div>
        <!-- 修改手机号 -->
        <div v-if="status==2">
          <p class="red m-b-6">更改手机号后，旧手机号名下的存酒将全部转移到新手机号下，请谨慎修改！</p>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>手机号:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <el-input
                v-model="phoneNum"
                size="small"
                style="width:200px;margin-right: 10px"
                placeholder="请输入手机号"
              ></el-input>
              <el-button
                :type="count == 0 ? 'primary' : 'info'"
                :disabled="count != 0"
                size="small"
                style="width:100px;height:30px"
                @click="sendPhoneMessage"
              >{{btnText}}</el-button>
            </div>
          </div>
          <div class="coll m-t-3" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>验证码:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <el-input
                v-model="validate"
                size="small"
                style="width:200px;margin-right: 10px"
                placeholder="请输入手机验证码"
              ></el-input>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      timer: null,
      count: 0, // 验证码倒计时
      userName: "",
      phoneNum: "",
      validate: ""
    };
  },
  methods: {
    interValHandle() {
      const storageSecondCount = this.$sessionStorage.getItem("secondCount"); // 获取发送短信时的时间戳
      const now = +new Date()
      const oneMinute = +new Date('2023/05/25 12:01:00') - +new Date('2023/05/25 12:00:00')
      if (now - storageSecondCount < oneMinute) {
        // 倒计时为结束接着倒计时
        this.count = ((oneMinute - (now - storageSecondCount)) / (oneMinute / 60)).toFixed(0) * 1;
        this.loopSecond();
      } else {
        this.count = 0;
      }
    },

    // 修改姓名
    async updateUserName() {
      const params = {
        p: this.userInfo.p, //   string   手机号码
        n: this.userName // string   客户姓名
      };
      if(params.n.length == 0) return this.$message.warning('请输入用户姓名')
      try {
        const res = await api_wine.reqUpdateCustomName(params);
        if (res.code == 1) {
          this.$message.success("修改成功");
          this.$emit("getTableData");
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("修改客户姓名失败", error);
      }
    },

    // 验证手机号是否有冲突
    async validatePhoneNum() {
      const params = {
        p: this.phoneNum //  string  手机号码
      };

      try {
        const res = await api_wine.reqValidatePhoneNum(params);
        if (res.code == 1) {
          return true;
        } else {
          this.$message.warning(res.msg);
          return false;
        }
      } catch (error) {
        console.log("验证手机号失败", error);
      }
    },

    // 发送验证码
    async sendPhoneMessage() {
      if (this.count != 0) return;
      this.count = 60

      if (this.phoneNum.length != 11)
        return this.$message.warning("请输入正确的11位手机号");

      const canSendMsg = await this.validatePhoneNum();

      if (!canSendMsg) return;

      const params = {
        t: 102, //  int   操作类型 101 创建记名卡 102 会员卡修改绑定手机 103 会员卡绑定手机  105 微信端客人绑定安全手机  200  验证获取客人会员卡结账
        m: this.phoneNum //  string   手机号
      };
      try {
        const res = await api_vip.reqSendPhoneMsg(params);
        if (res.code == 1) {
          this.$message.success("验证码发送成功");
          this.count--;
          this.loopSecond();
          this.$sessionStorage.setItem("secondCount", (+new Date()).toString());
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("发送验证码失败", error);
      }
    },

    // 倒计时
    loopSecond() {
      if (this.timer) clearInterval(this.timer);
      this.timer = setInterval(() => {
        this.count--;
        if (this.count == 0) {
          clearInterval(this.timer);
        }
      }, 1000);
    },

    // 验证修改手机号验证码
    async validatePhoneInfo() {
      const params = {
        m: this.phoneNum, //   string    手机号
        c: this.validate //    string   验证码
      };

      if (params.c.length != 5) {
        this.$message.warning("请输入正确的五位验证码");
        return false;
      }
      try {
        const res = await api_vip.reqValidatePhoneMsg(params);
        if (res.code == 1) {
          return res.data.c;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("验证手机验证码失败", error);
      }
    },

    // 修改手机号
    async updateUserPhoneNum(callback) {
      const authPhoneStr = await this.validatePhoneInfo();

      if (!authPhoneStr) return;

      const params = {
        p: this.userInfo.p, //   string  旧手机号码, 这里暂时不考虑老手机号的验证
        phone_num_auth_code: authPhoneStr, // string    认证新手机授权码
        n: this.phoneNum.toString() //  string   新手机号码
      };

      try {
        const res = await api_wine.reqUpdateCustomPhoneNum(params);
        if (res.code == 1) {
          this.$message.success("修改成功");
          callback && callback();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("修改手机号失败", error);
      }
    },

    onSubmit() {
      if (this.status == 1) {
        // 修改姓名
        this.updateUserName();
      } else if (this.status == 2) {
        this.updateUserPhoneNum(() => {
          clearInterval(this.timer);
          this.count = 0;
          this.$sessionStorage.setItem("secondCount", this.count.toString());
          this.onCancelDrawer();
          this.$emit("getTableData");
        });
      }
    },
    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    status: {
      default: 1
    },
    userInfo: {
      default: () => ({ n: "", p: "" })
    }
  },
  computed: {
    title() {
      return this.status == 1 ? "编辑姓名" : "修改手机号";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    btnText() {
      return this.count == 0 ? "发送验证码" : this.count + "s后发送";
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          if (this.status == 1) {
            this.userName = newVal.n;
          }
          if (this.status == 2) {
            this.interValHandle();
            this.phoneNum = "";
            this.validate = "";
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/wine/form.less";
</style>

<style lang="less" scoped>
.red {
  color: #D9001B;
}
</style>