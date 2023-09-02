<template>
  <div>
    <!-- 当前组件所用到的地方为：1、erp首页商品对照  2、物料管理-商品对照 -->
    <!-- 绑定erp商品 -->
    <div class="user-defined" v-show="ERPcommodity">
      <el-dialog title="绑定erp商品" :visible.sync="ERPcommodity">
        <div class="in_sum-rkrq">
          <div class="rkrq">
            <span>商品：</span>
            <el-cascader
              clearable
              :options="dept_items"
              :props="optionProps"
              v-model="dept_code"
              :show-all-levels="false"
              popper-class="liebdwd"
              ref="cascaderRef"
            ></el-cascader>
          </div>
          <div class="rkrq">
            <el-input v-model="erp_prds.name" placeholder="请输入erp商品名称 模糊查询"></el-input>
          </div>
          <div class="rkrq">
            <el-button type="primary" @click="prderp_prds">查询</el-button>
          </div>
        </div>
        <div style="display: inline-block;width: 602px; ">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th style="border-left:1px solid #f5f5f5">行号</th>
                <th>erp商品名称</th>
                <th>erp商品分类树描述</th>
                <th>单位</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody class="limiting">
              <tr
                v-for="(item,i) in erps_prdss"
                :key="i"
                class="drag-list"
                draggable="true"
                :class="checkedCitispes.includes(item.id)? 'drag-list-check':''"
              >
                <td :style="{'border-left':'1px solid #f5f5f5','color':item.s=='无效'?'#595959':''}">
                  <el-checkbox-group v-model="checkedCitispes" @change="changeCheckbox(item.id)">
                    <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                  </el-checkbox-group>
                  <!-- <el-radio v-model="checkedCitispes" :label="item.c">{{i+1}}&emsp;&ensp;</el-radio> -->
                </td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cp}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.un}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
              </tr>
              <tr class="drag-list" v-if="erps_prdss.length<1">
                <td class="nodata">
                  <img v-show="controlpicture ==1" src="../../../../assets/img/wu.png" alt />
                  <img v-show="controlpicture ==2" src="../../../../assets/img/empty_search.png" alt />
                  <img v-show="controlpicture ==3" src="../../../../assets/img/state_loading.png" alt />
                  <div v-show="controlpicture ==1" class="hint">暂无数据</div>
                  <div v-show="controlpicture ==2" class="hint">空-请检索</div>
                  <div v-show="controlpicture ==3" class="hint">加载中...</div>
                </td>
              </tr>
            </tbody>
          </table>
          <div class="Pagination">
            <el-pagination
              background
              layout="prev, pager, next"
              @current-change="handleCurrentChange"
              :page-size="erp_prds.page_size"
              :total="erp_prds.rowcnt"
            ></el-pagination>
          </div>
        </div>

        <span slot="footer" class="dialog-footer">
          <el-button type="default" @click.native="$emit('showOrHideDrawer')">取消</el-button>
          <el-button type="primary" @click.native="bindingERp">绑定</el-button>
        </span>
      </el-dialog>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      ERPcommodity: false,
      controlpicture: "2", // erp搜索商品
      dept_items: [], //ERP商品信息
      optionProps: {
        value: "id",
        label: "n",
        children: "subs",
        checkStrictly: true,
        expandTrigger: "hover"
      }, //规则
      erp_prds: {
        page_num: 1, //第几页
        page_size: 20, //每页行数
        is_init: 1, //页面初始化
        erp_cate_code: "", //erp商品分类编码
        name: "", //erp商品名称 模糊查询
        pagecnt: 1, //总页数
        rowcnt: 1 //总行数
      },
      dept_code: [], //商品分类树
      erps_prdss: [], //erp商品数据
      checkedCitispes: [] //已选择内容
    };
  },
  methods: {
    // 读取erp商品
    prderp_prds() {
      this.controlpicture = "3";
      this.erps_prdss = [];
      setTimeout(() => {
        this.$api.BMS.Prd.requestprderp_prds({
          page_num: this.erp_prds.page_num,
          page_size: this.erp_prds.page_size,
          is_init: this.erp_prds.is_init,
          erp_cate_id: this.erp_prds.erp_cate_code,
          name: this.erp_prds.name
        }).then(res => {
          if (res.code == 1) {
            if (res.data.erp_prds == null) {
              this.controlpicture = "1";
            }
            this.dept_items = res.data.erp_cates || [];
            this.erps_prdss = res.data.erp_prds || [];
            this.page_num = res.data.page_num;
            this.pagecnt = res.data.page_cnt;
            this.rowcnt = res.data.row_cnt;
          } else {
            this.$message.warning(res.msg);
          }
        });
      }, 1000);
    },
    // 选择商品
    changeCheckbox(id){
      this.checkedCitispes = [id]
    },
    // 绑定
    bindingERp() {
      if (this.checkedCitispes.length > 0) {
        const inventory = [];
        this.checkedCitispes.forEach(el => {
          const find = this.erps_prdss.find(item => item.id == el);
          if (find) inventory.push(find);
        });
        this.$emit("showOrHideDrawer");
        this.$emit("getBindList", { inventory, currentItem: this.currentItem });
      } else {
        this.$message.warning("绑定商品不能为空");
      }
    },
    // 当前是多少页
    handleCurrentChange(val) {
      console.log(`当前页: ${val}`);
      this.erp_prds.page_num = val;
      this.prderp_prds();
    }
  },
  created() {},
  mounted() {},
  props: {
    show: {
      default: false
    },
    currentItem: {
      default: {}
    }
  },
  watch: {
    show(newVal) {
      this.ERPcommodity = newVal;
      if (newVal) {
        this.controlpicture = "2";
        this.dept_code = []; //商品分类树
        this.erps_prdss = []; //erp商品数据
        this.erp_prds = {
          page_num: 1, //第几页
          page_size: 20, //每页行数
          is_init: 1, //页面初始化
          erp_cate_code: "", //erp商品分类编码
          // 首页中绑定erp商品，商品名称字段为pn ， 商品对照中字段为 n
          name: this.currentItem.n || this.currentItem.pn, //erp商品名称 模糊查询
          pagecnt: 1, //总页数
          rowcnt: 1 //总行数
        };

        this.prderp_prds();
      }
    },

    dept_code: {
      deep: true,
      handler(after, before) {
        this.erp_prds.erp_cate_code = after[after.length - 1];

        // this.prderp_prds()
        this.checkedCitispes = [];
        if (this.$refs.cascaderRef) {
          this.$refs.cascaderRef.dropDownVisible = false;
        }
      }
    },
  }
};
</script>

<style>

.user-defined .explain {
  margin-top: 20px;
  color: #ce4153;
  font-size: 12px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.user-defined .el-form {
  padding-top: 20px !important;
}

.user-defined .attribute {
  width: 350px;
  display: flex;
  flex-direction: column;
}

.user-defined .el-input {
  width: 230px;
}

.user-defined .el-form-item__content {
  display: flex;
  margin-bottom: 10px;
}

.user-defined .compatibil .compatibility {
  align-items: flex-start;
}

.user-defined .compatibil .compatibility .el-button {
  width: 40px;
  height: 40px;
  margin-left: 10px;
}


/* ERP商品 */
.in_sum-rkrq {
  color: #40404e;
  padding: 20px 0;
  display: flex;
}

.in_sum-rkrq .rkrq {
  margin-right: 15px;
  /* width: 280px; */
  display: flex;
  align-items: center;
}

.in_sum-rkrq .el-cascader__dropdown {
  background-color: #f5f5f5;
}

.in_sum-rkrq .rkrq > span {
  width: 50px;
  display: inline-block;
}

.in_sum-rkrq .rkrq .el-select {
  width: 230px;
}

.in_sum-rkrq .rkrq .el-input {
  width: 220px;
}

.in_sum-rkrq .rkrq:nth-of-type(3) {
  width: 240px;
}
</style>

<style>
/* 绑定epr商品 */
.user-defined .el-dialog {
  width: 650px !important;
  margin-top: 0 !important;
  float: right;
  margin-bottom: 0;
}

/* 一级分类下没二级分类的时候 */
.between {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 170px;
  padding-right: 400px;
}

.between img {
  width: 100px;
  height: 100px;
}

.between .period {
  margin-top: 30px;
  color: #a3a3a3;
  font-size: 18px;
}

/* */
/* 选中状态颜色背景边框 */
.el-radio-button__orig-radio:checked + .el-radio-button__inner {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #6a9eff !important;
  color: #6a9eff !important;
  box-shadow: none;
}

/* 表格无数据时展示 */
.tiaodd {
  position: sticky;
  left: 0;
  top: 44px;
  width: 100% !important;
  display: inline-block;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 0;
}

.nodata img {
  width: 60px;
  height: 60px;
}

.nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

/* 限制一级分类二级分类宽带 */
.stairastrict {
  max-width: 1000px;
  flex-shrink: 0;
}

/* 给一级分类二级分类加外边距和圆角 */
.el-radio-button {
  margin-right: 6px;
  margin-bottom: 6px;
  /* overflow: hidden; */
  /* border: 1px solid #f5f5f5; */
}

.el-radio-button__inner {
  border-radius: 4px !important;
  padding: 6px 20px;
  font-size: 14px;
  height: 30px;
}

.el-radio-button__inner-div {
  padding: 0 20px;
}

/* 去除瑕疵 */
.el-radio-button__orig-radio:checked + .el-radio-button__inner + {
  box-shadow: none;
}

/*去除双击文字、input等，出现的蓝色底色*/
.container {
  -moz-user-select: none; /*火狐*/
  -webkit-user-select: none; /*webkit浏览器*/
  -ms-user-select: none; /*IE10*/
  /*-khtml-user-select:none;!*早期浏览器*!*/
  user-select: none;
  height: 30px;
}

.user-defined table {
  border-collapse: collapse;
  color: #40404e;
}

.user-defined table thead th {
  height: 40px;
  /* min-height: 40px; */
  line-height: 40px;
  text-align: left;
  background-color: #f5f5f5;
  font-weight: 400;
  font-size: 14px;
  padding-left: 20px;
}

.user-defined table tbody tr:nth-child(2n + 1) {
  background-color: #f9f9f9;
}
.user-defined table tbody tr:nth-child(2n) {
  background-color: #f5f5f5;
}

.user-defined table tbody td {
  height: 40px;
  min-height: 40px;
  line-height: 20px;
  text-align: left;
  white-space: normal;
  word-break: break-all;
  font-size: 14px;
  font-weight: 400;
  padding-left: 20px;
}

.el-checkbox__label {
  color: #40404e;
}

.List-move {
  transition: transform 0.2s;
}

.tolead .el-dialog {
  width: 30vw !important;
  min-width: 410px !important;
  max-width: 460px !important;
}

.feedback .el-dialog {
  width: 1300px !important;
}


.check {
  color: #40404e;
}

.el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.el-dialog {
  background-color: #f9f9f9;
}

.el-input__inner {
  background-color: transparent;
  color: #40404e;
}

.el-dialog__header,
.el-dialog__footer {
  background-color: #1a1a21;
}

.el-dialog__title,
.el-dialog__headerbtn .el-dialog__close,
.el-form-item__label {
  color: #40404e;
  display: flex;
  align-items: center;
}

.el-form-item {
  display: flex;
  margin: 0;
}

.el-button.el-button--default {
  background-color: #ccc!important;
  border: 1px solid #ccc!important;
  color: #40404e!important;
}
</style>

<style>
/* 分页 */
.Pagination {
  /* width: 1093px; */
  text-align: right;
  margin-top: 20px;
}

.Pagination .el-pagination.is-background .btn-next,
.Pagination .el-pagination.is-background .btn-prev,
.Pagination .el-pagination.is-background .el-pager li {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
  color: #40404e;
}

.Pagination .btn-prev {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
}

.Pagination .el-pagination {
  padding: 0;
}

.Pagination .el-pagination .btn-next .el-icon,
.Pagination .el-pagination .btn-prev .el-icon {
  color: #40404e;
}

.el-pagination.is-background .el-pager li:not(.disabled).active {
  color: #409eff;
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #409eff;
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
  color: #40404e;
}

.el-cascader-node.in-active-path,
.el-cascader-node.is-active,
.el-cascader-node.is-selectable.in-checked-path {
  color: #409eff !important;
  background-color: #e5e5e5;
}

.el-radio__inner::after {
  background-color: #e5e5e5;
}

.el-cascader-node__label {
  color: #40404e;
}

.el-cascader-menu {
  border-right: solid 1px #4d4e5c;
}

/* 级联选择器 */
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
  background: transparent!important;
}
</style>

<style scoped>

.user-defined .zhuixiaoi {
  min-width: 602px !important;
  width: 602px;
  overflow: hidden;
  display: inline-block;
}

.user-defined .drag-list td:nth-of-type(1),
.user-defined .mmodity th:nth-of-type(1) {
  width: 12%;
}

.user-defined .drag-list td:nth-of-type(2),
.user-defined .mmodity th:nth-of-type(2) {
  width: 20%;
}

.user-defined .drag-list td:nth-of-type(3),
.user-defined .mmodity th:nth-of-type(3) {
  width: 20%;
}

.user-defined .drag-list td:nth-of-type(4),
.user-defined .mmodity th:nth-of-type(4) {
  width: 15%;
}

.user-defined .drag-list td:nth-of-type(5),
.user-defined .mmodity th:nth-of-type(5) {
  width: 10%;
}

.user-defined tbody.limiting {
  width: 100%;
  height: calc(100vh - 332px);
  overflow: auto !important;
  display: block;
}


/* 表格全选字体颜色 */
.between .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

.between .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}



.zhuixiaoi {
  /*min-width: 867px;*/
  overflow: hidden;
  display: inline-block;
  /*margin-top: 6px;*/
}


.zhuixiaoi thead,
.zhuixiaoi thead tr,
.zhuixiaoi tbody tr {
  width: 100% !important;
}

.zhuixiaoi .drag-list {
  display: inline-block;
  width: 100% !important;
}
</style>