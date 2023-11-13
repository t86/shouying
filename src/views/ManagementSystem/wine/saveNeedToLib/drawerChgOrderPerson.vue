<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="60%"
      append-to-body
    >
      <div class="session p-3 fs14">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="col" style="width: 100%;">
          <div class="item" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <div class="label m-r-4">订位人:</div>
            <div class="input-select">
              <input-select
              :autoFocus="true"
              :value="employee.n"
              placeholder="请输入姓名或工号"
              :optionsList="optionEployees"
              @selectInputHandle="inputEmployeeName"
              @selectOptionItem="changeEmployeeName"
              @selectBlurHandle="selectBlurHandle"
            ></input-select>
            </div>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button size="small" type="info" @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" size="small" @click="submitHandle">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import inputSelect from "@/components/book/inputSelect";
import api_wine from "@/api/wine";

export default {
  data() {
    return {
      show: false,
      // 筛选条件
      employee: {},
      employeeList: [],
      optionEployees: [],
    };
  },
  methods: {
    async inputEmployeeName(query){

      this.employee.n = query;
      this.employee.id = ''
      this.employee.p = ''
      this.employee.c = ''
      if(this.employeeList.length == 0) {
        try {
          const res = await api_wine.reqGetChgSalesEmpList();
          if (res.code == 1) {
            this.employeeList = res.data.records.map(item => { return {
              ...item,
              name: item.n,
              code: item.c
            }
          });
          } else {

          }

        } catch (error) {
          console.log("订位人信息获取失败", error);
        }
      }
      this.optionEployees = this.employeeList.filter((el) =>
              el.c.toString().includes(query) ||
              el.n.toString().includes(query) ||
              el.p.toString().includes(query.toLowerCase()))
    },
    changeEmployeeName(info){
      this.employee.n = info.n
      this.employee.id = info.id
      this.employee.c = info.c
      this.optionEployees = [];
    },
    selectBlurHandle(){
      this.optionEployees = [];
    },
    async submitHandle() {
      if(!this.employee.c) {
        return this.$message.warning("请选择订位人");
      }
      this.$emit("onSubmit", {
        ...this.employee
      });
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.$emit("showOrHideDrawerHandle");
    },
  },
  props: {
    showDrawer: {
      default: false
    },
    item: {}
  },
  computed: {
    title() {
      return "更改订位人" 
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.datetime = this.item.t
      }
    }
  },
  components: {
    inputSelect
  },
};
</script>

<style scoped lang="less">
@import "./drawerchg.less";
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.reqfieldsd {
  font-size: 16px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.input-select {
  position: relative;
}

/deep/ul.options {
    background-color: #ffffff!important;
  li {
    color: #000!important;;
  }
}

.el-icon-arrow-right:before {
  color: #606266;
}

/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}
.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
.el-range-editor--small .el-range-input {
  background-color: transparent;
}

.el-picker-panel__footer {
  background-color: #eaecf3;
  border: 1px solid #838786
}
.el-button--default {
  background-color: #fff;
}
</style>
