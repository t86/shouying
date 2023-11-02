<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="80%"
    >
      <div class="session p-3 fs14">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="col" style="width: 100%;">
          <div class="item p-2" layout="row" layout-align="start center">
            <div class="label">当前类别: 特殊分类</div>
          </div>
          <div class="item p-2" layout="row" layout-align="start center">
            <div class="label">商品分类：</div>
            <div class="value" style="margin: 0 10px">
              <el-cascader
                clearable
                size="small"
                :options="cateOptions"
                v-model="cateVal"
              ></el-cascader>
            </div>
            <div class="m-l-2 m-r-2" style="flex:1;" >
              <el-input v-model="name" placeholder="输入商品名称或拼音字母" size="small"></el-input>
            </div>
            <el-button type="primary" size="small" @click="getTableData(2)">查询</el-button>
            <el-button type="info" size="small" @click="resetHandle">重置</el-button>
          </div>

          <div class="m-t-3 m-b-3">
            <el-button type="primary" size="small" @click="batchAddPrd">批量添加</el-button>
            <el-button size="small" type="primary" @click="deleteHandle">批量删除</el-button>
          </div>
        </div>

        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="checked"
                    :indeterminate="indeterminate"
                    @change="changeCheckboxHandle('all')"
                  >序号</el-checkbox>
                </div>
                <div class="th">商品名称</div>
                <div class="th">商品分类</div>
                <div class="th">商品类型</div>
                <div class="th">营业类型</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData" :key="item.id">
                <div class="td">
                  <el-checkbox v-model="item.checked" :checked="item.checked" :disabled="item.disabled" @change="changeCheckboxHandle('item')">{{index+1}}</el-checkbox>
                </div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{ item.on }} > {{ item.tn }}</div>
                <div class="td">{{ item.t }}</div>
                <div class="td">{{item.b}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button size="small" type="info" @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" size="small" @click="submitHandle">确定</el-button>
      </div>

      <drawerAddPrdCom
        :showDrawer="showAddDrawer"
        :item="item"
        @showOrHideDrawerHandle="showOrHideAddDrawerHandle"
      />

    </el-drawer>
  </div>
</template>
 
<script>

export default {
  data() {
    return {
      checked: false,
      indeterminate: false,
      show: false,
      // 筛选条件
      tableData: [],
      name: '',
      cateVal: [0,0],
      cateOptions: [],
      showAddDrawer: false,
    };
  },
  methods: {
    batchAddPrd(){
      this.showOrHideAddDrawerHandle()
    },
    showOrHideAddDrawerHandle(items = null){
      this.showAddDrawer = !this.showAddDrawer
      if(items != null) {
        this.tableData = [...items]
      }

    },
    async deleteHandle(){
      try {
        const params = {
          id: this.item.id,
          prd_ids: this.tableData.filter(item => item.checked && !item.disabled).map(item => item.id)
        }
        if (!params.prd_ids || params.prd_ids.length <= 0) {
          this.$message.warning("至少选择一个要删除的商品")
        }
        const res = await this.$api.BMS.statiscalConfig.reqBatchDelRptJkCatePitems(params)
        if(res.code == 1) {
          this.tableData = this.tableData.filter(item => !params.prd_ids.includes(item.id))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("读取统计分类列表失败", error);
      }
    },
    changeCheckboxHandle(type){
      switch(type) {
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
    async getTableData(init = 1) {
      try {
        const params = {
          id: this.item.id,
          init: init,
          one_cate_id: this.cateVal[0],
          two_cate_id: this.cateVal[1],
          name: this.name
        }
        const res = await this.$api.BMS.statiscalConfig.reqGerRptJkCatePrdList(params)
        if(res.code == 1) {
          if(init == 1) {
            const cateOptions = res.data.cates || [];
            cateOptions.filter(el => el.ss).forEach(el => {
              el.value = el.id;
              el.label = el.n;
              el.ss.forEach(ele => {
                ele.value = ele.id;
                ele.label = ele.n;
              });
              el.children = el.ss;
            });

            this.cateOptions = cateOptions;     
          }
          this.tableData = (res.data.prds || []).map((item) => {
            item.on = this.cateOptions.find(
              (i) => i.value == item.oc
            ).n;
            item.tn = this.cateOptions
              .find((i) => i.value == item.oc && i.children)
              .children.find((i) => i.value == item.tc).n;
            return {
              ...item
            };
          });
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("读取统计分类列表失败", error);
      }
    },
    async submitHandle() {
      const params = {
        id: this.item.id,//   []int64   
        prd_ids: this.tableData.map(item => item.id),
      };
      try {
        const res = await this.$api.BMS.statiscalConfig.reqBatchAddRptJkCatePitems(params)
        if(res.code == 1) {
          this.closeDrawerHandle();
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("添加商品到统计类别失败", error);
      }
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.cateVal = [0,0]
      this.name = ""
      this.$emit("showOrHideDrawerHandle");
    },
    resetHandle(){
      this.getTableData(1)
    },
  },
  props: {
    showDrawer: {
      default: false
    },
    item: {
      default: {}
    }
  },
  computed: {
    title() {
      return "配置" 
    },

  },
  components: {
    drawerAddPrdCom: () => import('./drawerAddPrdCom.vue'),
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getTableData(1)
      }
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
</style>
<style scoped lang="less">
@import "./drawerAddStatCom.less";
</style>

<style>
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

.el-icon-arrow-right:before {
  color: #606266;
}
</style>