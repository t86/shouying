<template>
  <div>
    <!-- 新增或修改供应商 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>供应商名称：</span>
          </div>
          <div class="value">
            <el-input
              v-model="supplierName"
              size="mini"
              @input="inputHandle"
              placeholder="请输入十个字以内的供应商名称"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>联系人：</span>
          </div>
          <div class="value">
            <el-input
              v-model="person"
              size="mini"
              placeholder="请输入联系人"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>手机号码：</span>
          </div>
          <div class="value">
            <el-input
              v-model="phone"
              size="mini"
              placeholder="请输入手机号码"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>电子邮箱：</span>
          </div>
          <div class="value">
            <el-input
              v-model="email"
              size="mini"
              placeholder="请输入电子邮箱"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>地址：</span>
          </div>
          <div class="value">
            <el-input
              v-model="address"
              size="mini"
              placeholder="请输入地址"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>备注：</span>
          </div>
          <div class="value">
            <el-input
              type="textarea" 
              v-model="remark" 
              :rows="3" 
              placeholder="请输入备注" 
              />
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
export default {
  data() {
    return {
      supplierName: "",
      person: "",
      phone: '',
      email: '',
      address: '',
      remark: ''
    };
  },
  methods: {
    async onSubmit() {
      if (this.supplierName.length <= 0)
        return this.$message.warning("请输入供应商名称");
      const params = {
        name: this.supplierName,
        contact_name: this.person,
        phone_num: this.phone,
        email: this.email,
        addr: this.address,
        remark: this.remark,
        ...this.type == 2 && {id : this.currentInfo.id}
      };
      try {
        const api = this.type == 1 ? 'requestsuppliernew' : 'requestsuppliersave'
        const res = await  this.$api.ERP.supplier[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData')
          this.$message.success('操作成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
      }
    },

    async getDetailInfo() {
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await  this.$api.ERP.supplier.requestsupplierget(params)
        if(res.code == 1) {
          this.supplierName = res.data.name || "";
          this.person = res.data.contact_name || "";
          this.phone = res.data.phone_num || "";
          this.email = res.data.email || "";
          this.address = res.data.addr || "";
          this.remark = res.data.remark || "";
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取详细信息失败', error);
      }
    },

    inputHandle() {
      this.$overall.character(this.supplierName) > 20
        ? this.$message.warning("最大长度为10")
        : "";
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
    type: {
      default: 1
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增供应商" : "编辑供应商";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          if (this.type == 1) {
            this.supplierName = "";
            this.person = "";
            this.phone = "";
            this.email = "";
            this.address = "";
            this.remark = "";
          } else {
            this.getDetailInfo()
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../style/common/elementDrawerWine.less";
@import "../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../style/erp/form.less";
</style>