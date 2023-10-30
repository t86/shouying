<template>
  <div>
    <!-- 批量修改部门 / 批量修改直属上级  /  批量重置密码 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      :size="size"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div v-if="otherType == 1">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>部门：</span>
            </div>
            <div class="value">
              <el-cascader
                size="small"
                placeholder="请选择部门"
                clearable
                :options="deptOption"
                :props="optionProp"
                v-model="deptIds"
                >
              </el-cascader>
            </div>
          </div>
        </div>
        <div v-if="otherType == 2">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>员工直属上级：</span>
            </div>
            <div class="value">
              <el-select
                v-model="upperEmpId"
                filterable
                remote
                reserve-keyword
                placeholder="请输入姓名或工号"
                :remote-method="remoteEmpHandle"
                :loading="loading">
                <el-option
                  v-for="item in upperEmpOption"
                  :key="item.id"
                  :label="item.n"
                  :value="item.id">
                </el-option>
              </el-select>
            </div>
          </div>
        </div>
        <div v-if="otherType == 5">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>岗位：</span>
            </div>
            <div class="value">
              <el-select
                v-model="upperStaId"
                placeholder="选择岗位"
                :loading="loading">
                <el-option
                  v-for="item in upperStaOption"
                  :key="item.id"
                  :label="item.n"
                  :value="item.id">
                </el-option>
              </el-select>
            </div>
          </div>
        </div>
        <div v-if="otherType == 4">
          <el-input
              v-model="resetPwd"
              placeholder="请输入重置密码"
              class="controlling"
            />
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确认</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      deptOption: [], //部门信息
      deptIds: [],//选中的分类
      optionProp: {
        value: 'id',
        label: 'n',
        children: 'subs',
        expandTrigger: 'hover'
      },

      loading: false,
      upperEmpOption: [],
      upperEmpId: '',
      upperStaOption: [],
      upperStaId: '',
      resetPwd: '',
    };
  },
  methods: {
    async getDeptOption(){
      try {
        const res = await this.$api.BMS.dept.requestDeptTree()
        if(res.code == 1) {
          this.deptOption = res.data || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取部门数据请求失败', error);
      }
    },

    async submitDeptInfo(){
      if(this.deptIds.length == 0) return this.$message.warning('请选择部门')
      const params = {
        emp_ids: this.checkedList.map(item => item.id * 1),
        dept_id: this.deptIds[this.deptIds.length - 1], //部门Id
      }
      try {
        const res = await this.$api.BMS.emp.requestEmpUpdDept(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    // 获取岗位列表
    async remoteStationHandle(){
      this.loading = true;
      try {
        const res = await this.$api.BMS.emp.requestEmpStationList()
        if(res.code == 1) {
          this.upperStaOption = res.data.records || []
          this.loading = false;
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('远程搜索失败', error); 
      }
    },

    async remoteEmpHandle(query){
      if (query !== '') {
        this.loading = true;
        const params = {
          name: query,
          page_num: 1,
          page_size: 9999999,
          mod_emp_ids: []
        }
        try {
          const res = await this.$api.BMS.emp.requestEmpUpperItems(params)
          if(res.code == 1) {
            this.upperEmpOption = res.data || []
            this.loading = false;
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('远程搜索失败', error); 
        }
      } else {
        this.upperEmpOption = [];
      }
    },

    // 批量修改直属上级
    async submitUpEmpInfo(){
      const params = {
        emp_ids: this.checkedList.map(item => item.id * 1),
        upper_emp_id: this.upperEmpId * 1 //直属上级Id
      }
      if(params.emp_ids == '') return this.$message.warning('请选择直属上级')
      try {
        const res = await this.$api.BMS.emp.requestEmpBatchUpdUpper(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.message.warning(res.msg)
        }
      } catch (error) {
        console.log('批量修改直属上级请求失败', error);
      }
    },

    // 批量修改岗位
    async submitUpStaInfo(){
      const params = {
        emp_ids: this.checkedList.map(item => item.id * 1),
        station_id: this.upperStaId * 1 //
      }
      if(params.station_id == '') return this.$message.warning('请选择目标岗位')
      try {
        const res = await this.$api.BMS.emp.requestBatchUpdateStationList(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.message.warning(res.msg)
        }
      } catch (error) {
        console.log('批量修改岗位请求失败', error);
      }
      this.upperStaOption = []
      this.upperStaId = ''
    },

    // 批量重置密码 
    async submitResetPwdInfo(){

      if(!this.resetPwd) {
        this.message.warning('请输入重置密码')
        return
      }

      const params = {
        ids: this.checkedList.map(item => item.id * 1),
        new_passwd: this.resetPwd,
      }
      try {
        const res = await this.$api.BMS.emp.requestEmpBatchResetPwd(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('onCancelDrawer')
        } else {
          this.message.warning(res.msg)
        }
      } catch (error) {
        console.log('批量重置密码请求失败', error);
      }
    },

    onSubmit() {
      if(this.otherType == 1) {
        this.submitDeptInfo()
      } else if(this.otherType == 2) {
        this.submitUpEmpInfo()
      } else if(this.otherType == 4) {
        this.submitResetPwdInfo()
      } else if(this.otherType == 5) {
        this.submitUpStaInfo()
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
    checkedList:{
      default: () => ([])  // 选中的员工列表
    },
    otherType: {
      default: 1 // 1：批量修改部门  2：批量修改直属上级   4：批量重置密码
    }
  },
  computed: {
    title() {
      return this.otherType == 1
        ? "批量修改部门"
        : this.otherType == 2
        ? "批量修改直属上级"
        : this.otherType == 5 
        ? "批量修改岗位" : "批量重置密码";
    },

    size() {
      return this.otherType == 4 ? '500px' : '720px'
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
          if(this.otherType == 1) {
            this.getDeptOption()
          } else if (this.otherType == 5) {
            this.remoteStationHandle()
          }
          
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../../style/erp/form.less";
@import "../../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  margin-top: 16px;
  .label {
    width: 120px;
  }
}

.controlling {
  width: 230px !important;
  line-height: 34px;
}
</style>