<template>
    <div class="smgr">
        <div class="in_sum-rkrq">
            <div class="rkrq">
                <span>部门：</span>
                <el-cascader
                        clearable
                        :options="dept_items"
                        :props="optionProps"
                        v-model="dept_code"
                        :show-all-levels="false"
                        popper-class='liebdwd'
                        ref="cascaderRef">
                </el-cascader>
            </div>
            <div class="rkrq">
                <span>岗位：</span>
                <el-select v-model="station_code" placeholder="全部" clearable>
                    <el-option label="全部" value=""></el-option>
                    <el-option v-for="(item) in post" :key="item.id" :label="item.n" :value="item.id"></el-option>
                </el-select>
            </div>
            <div class="rkrq">
                <el-input v-model="name" placeholder="请输入工号或姓名 模糊查询"></el-input>
            </div>
            <div class="rkrq">
                <el-button type="primary" @click="demand">查询</el-button>
            </div>
        </div>
        <div class="smgr-controller">
            <el-button type="primary" @click="batchrocessing">批量重置密码</el-button>
        </div>


        <div style="display: inline-block;">
            <table class="zhuixiaoi">
                <thead class="mmodity">
                <tr>
                    <th>
                        <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                            全选&ensp;
                        </el-checkbox>
                    </th>
                    <th>员工姓名</th>
                    <th>部门名称</th>
                    <th>岗位名称</th>
                    <th>状态</th>
                </tr>
                </thead>
                <tbody class="limiting">
                <tr v-for="(item,i) in tableData" :key="i" class="drag-tableData">
                    <td>
                        <el-checkbox-group v-model="checkedCities" @change="handleCheckedCitiesChange">
                            <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                        </el-checkbox-group>
                    </td>
                    <td>{{item.n}}</td>
                    <td>
                        {{item.d}}
                    </td>
                    <td>
                        {{item.sn}}
                    </td>
                    <td>
                        {{item.s}}
                    </td>

                </tr>
                <tr class="drag-tableData" v-if="tableData.length<1">
                    <td class="nodata">
                        <img src="../../../../assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </tr>
                </tbody>
            </table>
            <div class="Pagination">
                <el-pagination
                        background
                        layout="prev, pager, next"
                        @current-change="handleCurrentChange"
                        :page-size="page_size"
                        :total="rowcnt">
                </el-pagination>
            </div>
        </div>
    </div>
</template>
<script>
export default {
  data(){
    return {
      tableData: [],//员工数据
      dept_items: [],//部门信息
      post: [],// 岗位信息
      dialogFormVisible: false,//控制新建供应商是否显示
      Reddasheddispose: false,


      checkAll: false,//全部选中触发
      checkedCities: [],//已选择内容
      isIndeterminate: false,//全选或者全不选

      page_num: 1,//第几页
      page_size: 10,//每页行数
      is_init: 1, //1 页面初始化
      dept_code: [],//部门编码
      station_code: '',//岗位编码
      name: '',//工号或姓名 模糊查询
      pagecnt: 1,//总页数
      rowcnt: 1,//总行数
      optionProps: {
        value: 'id',
        label: 'n',
        children: 'subs',
        checkStrictly: true,
        expandTrigger: 'hover'
      },


    }
  },
  mounted(){
    this.demand()
  },
  computed: {},
  methods: {
    // 获取用户列表
    demand(){
      console.log(this.dept_code);
      console.log(this.station_code);
      this.$api.BMS.emp.requestemplist({
        page_num: Number(this.page_num),
        page_size: Number(this.page_size),
        is_init: Number(this.is_init),
        dept_id: this.dept_code[this.dept_code.length - 1] || '',
        station_id: this.station_code || '',
        name: this.name,
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.pagecnt = res.data.page_cnt
          this.rowcnt = res.data.row_cnt
          this.page_num = res.data.page_num
          this.tableData = res.data.emps || []
          this.dept_items = res.data.dept_items || []

          this.checkAll = false
          this.checkedCities = []
          this.isIndeterminate = false
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      if (val) {
        this.checkedCities = []
        for (const key in this.tableData) {
          this.checkedCities.push(this.tableData[key].c)
        }
      } else {
        this.checkedCities = []
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableData.length;
      // console.log(this.checkedCities);
    },
    // 批量重置密码
    batchrocessing(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.emp.requestempbatch_reset_pwd({emp_ids: this.checkedCities}).then(res => {
          console.log(res);

          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.demand()

          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请最少选择一个进行重置',
          type: 'warning',
        })
      }
    },
    // 当前是多少页
    handleCurrentChange(val) {
      console.log(`当前页: ${val}`);
      this.page_num = val
      this.demand()
    },
    // 选中部门出现岗位
    sdfws(){
      var s = this.$refs.cascaderRef.getCheckedNodes().length != 0 ? this.$refs.cascaderRef.getCheckedNodes()[0].data : this.dept_items[0]
      var w = []
      if (s) {
        for (const key in s.sts) {
          w.push(s.sts[key])
        }
      }
      if (s.subs) {
        const teamTree = function (arr) {
          for (let i = 0; i < arr.length; i++) {
            if (arr[i].sts) {
              for (const key in arr[i].sts) {
                w.push(arr[i].sts[key])
              }
            }
            if (arr[i].subs) {
              teamTree(arr[i].subs)
            }
          }
        }
        teamTree(s.subs)
      }
      console.log(w);
      this.post = this.unique(w)
    },
    // 去重
    unique(arr) {
      const res = new Map();
      return arr.filter((arr) => !res.has(arr.id) && res.set(arr.id, 1));
    },

  },
  watch: {
    dept_code: {
      deep: true,
      handler: function (after, before) {
        console.log(after);
        this.sdfws()
        this.station_code = ''
        this.$refs.cascaderRef.dropDownVisible = false
      }
    }
  }
}
</script>
<style>
    .smgr {
        width: calc(100% - 40px);
        height: calc(100% - 80px);
        padding: 40px 20px;
    }

    .tbdgf {
        display: flex;
        justify-content: center;
        align-items: center;
    }

    .tbdgf img {
        width: 15px;
        height: 15px;
        margin-left: 3px;
    }

    .item {
        margin: 4px;
    }

    .liebdwd .el-radio__inner {
        top: -18px;
        left: -19px;
        border-radius: 0;
        border: 0;
        width: 170px;
        height: 34px;
        background-color: transparent;
        cursor: pointer;
        box-sizing: border-box;
        position: absolute;
    }

    .liebdwd .el-radio__input.is-checked .el-radio__inner {
        background: transparent;
    }

    .smgr .in_sum-rkrq {
        /* margin-top: 10px;
        margin-bottom: 10px; */
        color: #40404e;
        padding: 20px 0;
        display: flex;
    }

    .smgr .in_sum-rkrq .rkrq {
        margin-right: 15px;
        width: 280px;
        display: flex;
        align-items: center;
    }

    .smgr .in_sum-rkrq .rkrq > span {
        width: 50px;
        display: inline-block;
    }

    .smgr .in_sum-rkrq .rkrq .el-select {
        width: 230px;
    }

    .smgr .in_sum-rkrq .rkrq .el-input {
        width: 220px;
    }

    .smgr .in_sum-rkrq .rkrq:nth-of-type(3) {
        width: 240px;
    }

    .smgr .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 分页 */
    .smgr .Pagination {
        /* width: 1093px; */
        text-align: right;
        margin-top: 20px;
    }

    .smgr .Pagination .el-pagination.is-background .btn-next, .smgr .Pagination .el-pagination.is-background .btn-prev, .smgr .Pagination .el-pagination.is-background .el-pager li {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
        color: #40404e;
    }

    .smgr .Pagination .btn-prev {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
    }

    .smgr .Pagination .el-pagination {
        padding: 0;
    }

    .smgr .Pagination .el-pagination .btn-next .el-icon, .smgr .Pagination .el-pagination .btn-prev .el-icon {
        color: #40404e;
    }

    .smgr .Pagination .el-pagination.is-background .el-pager li:not(.disabled).active {
        color: #409EFF;
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #409EFF;
    }

    /* 下拉框 */
    .el-select-dropdown__wrap {
        background-color: #f5f5f5;
    }

    .el-select-dropdown__empty {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .el-select-dropdown__item.selected {
        background-color: #e5e5e5;
    }

    .el-select__popper.el-popper[role="tooltip"] {
        border: 1px solid #f5f5f5;
    }

    .el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"] .el-popper__arrow::before {
        border: 1px solid #f5f5f5;
        background-color: #f5f5f5;
    }

    .el-select-dropdown__item.hover, .el-select-dropdown__item:hover {
        background-color: #e5e5e5;
    }

    .el-select-dropdown__item.selected {
        color: #40404e;
    }

    .el-select-dropdown__item {
        color: #40404E
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    .xdownbox {
        display: none;
    }

    /* 级联选择器 */
    .el-cascader__dropdown {
        border: 1px solid #f5f5f5;
    }

    .el-cascader-menu__wrap {
        background-color: #f5f5f5;
    }

    .el-cascader-node:not(.is-disabled):hover {
        background-color: #e5e5e5;
        color: #40404e
    }

    .el-cascader-node.in-active-path, .el-cascader-node.is-active, .el-cascader-node.is-selectable.in-checked-path {
        color: #409EFF !important;
        background-color: #e5e5e5;
    }

    .el-radio__inner::after {
        background-color: #e5e5e5;
    }

    .el-cascader-node__label {
        color: #40404e
    }

    .el-cascader-menu {
        border-right: solid 1px #4d4e5c;
    }

    .apply {
        margin-top: 30px;
        font-size: 20px;
        color: #40404e;
    }

    .ewdetai {
        color: #438dfd !important;
        width: 40px;
        height: 40px;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .imgfzs {
        display: flex;
        justify-content: center;
        align-items: center;
    }

    .imgfzs img {
        width: 20px;
        height: 20px;
    }

    /* 必填 */
    .smgr .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        padding-top: 10px;
    }

    .smgr .controlling {
        width: 230px !important;
    }

    .smgr .reqfieldsd {
        font-size: 16px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格无数据时展示 */
    .smgr .drag-tableData .nodata {
        border-left: solid 1px #f5f5f5;
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .smgr .drag-tableData .nodata img {
        width: 60px;
        height: 60px;
    }

    .smgr .drag-tableData .nodata .hint {
        font-size: 13px !important;
    }

    /* 内容 */
    .smgr .smgr-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .smgr .smgr-controller {
        margin-bottom: 30px;
    }

    .smgr .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .smgr .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }

    .smgr .compatibil {
        margin-bottom: 10px;
    }

    .smgr .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .smgr .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .smgr table thead tr th, .smgr table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    /* 改变多选框背景颜色和上下间距 */
    .smgr .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: center;
    }

    .smgr .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .smgr .el-input__count {
        background-color: #1A1A20;
        color: #40404e;
        right: -45px;
        height: 20px;
        bottom: 5px;
        line-height: 20px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 仓库列表 */
    .smgr .zhuixiaoi {
        width: 650px;
        border-collapse: collapse;
        /* border: solid 1px #f5f5f5; */
        color: #40404e;
    }

    .smgr .zhuixiaoi .mmodity tr th {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #f5f5f5;
        border-top: solid 1px #f5f5f5;
        background-color: #2d2e38;
        font-size: 14px;
        font-weight: 400;
    }

    .smgr .zhuixiaoi .mmodity tr th:nth-of-type(1) {
        border-left: solid 1px #f5f5f5;
    }

    .smgr .zhuixiaoi .limiting .drag-tableData td {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #f5f5f5;
        border-top: solid 1px #f5f5f5;
        font-size: 14px;
        font-weight: 400;
    }

    .smgr .zhuixiaoi .limiting .drag-tableData td:nth-of-type(1) {
        border-left: solid 1px #f5f5f5;
    }

    .smgr .zhuixiaoi .limiting .drag-tableData {
        display: block;
        /* width: calc(100% - 17px); */
        display: flex;
    }

    .smgr .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .smgr .zhuixiaoi .mmodity tr {
        display: flex;
    }

    .smgr .zhuixiaoi .limiting {
        /* width: calc(100% + 17px);  */
        /* width: 100%;  */
        overflow-y: auto !important;
        max-height: 620px !important;
        border-bottom: solid 1px #f5f5f5;
        /* width: 100%; */
        display: block;
    }

    .smgr .drag-tableData td:nth-of-type(1), .smgr .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .smgr .mmodity th:nth-of-type(2), .smgr .drag-tableData td:nth-of-type(2) {
        width: 200px;
    }

    .smgr .drag-tableData td:nth-of-type(3), .smgr .mmodity th:nth-of-type(3) {
        width: 150px;
    }

    .smgr .drag-tableData td:nth-of-type(4), .smgr .mmodity th:nth-of-type(4) {
        width: 150px;
    }

    .smgr .drag-tableData td:nth-of-type(5), .smgr .mmodity th:nth-of-type(5) {
        width: 70px;
    }

    .smgr .drag-tableData td:nth-of-type(6), .smgr .mmodity th:nth-of-type(6) {
        width: 70px;
    }

    .smgr .drag-tableData td:nth-of-type(7), .smgr .mmodity th:nth-of-type(7) {
        width: 70px;
    }

    .smgr .drag-tableData:nth-of-type(odd) td {
        background-color: #1A1A20;
        color: #40404e;
    }

    .smgr .drag-tableData:nth-of-type(even) td {
        background-color: #1F1F25;
        color: #40404e;
    }

    /* 全选颜色 */
    .smgr .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .smgr .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }


</style>



