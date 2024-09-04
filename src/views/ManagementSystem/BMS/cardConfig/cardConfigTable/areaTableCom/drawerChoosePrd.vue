<template>
  <div>
    <!-- 新增或修改区域 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="900px"
    >
      <div class="session p-5 fs14">
        <div class="m-t-2 m-b-2" layout="row" layout-align="start center">
          <span>商品分类：</span>
          <el-cascader
            clearable
            size="small"
            :options="cateOptions"
            v-model="cateVal"
          ></el-cascader>
          <el-input class="m-l-2" v-model="keyword" size="samll" style="width: 200px" placeholder="请输入商品名称"></el-input>
          <div class="m-l-2">
            <el-button style="background:#2170ff" type="primary" @click="getPrdCategoryAndPrdList(1)">查询</el-button>
            <el-button type="info" @click="resetSelectHandle">重置</el-button>
          </div>
        </div>

        <div class="table-content m-t-3">
          <div class="table" v-infinite-scroll="getPrdCategoryAndPrdList">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th">单品名称</div>
                <div class="th">分类</div>
                <div class="th">单价</div>
                <div class="th">商品类型</div>
                <div class="th">营业类型</div>
                <div class="th">状态</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" v-for="(item,i) in tableData" :key="item.id" layout="row" layout-align="space-between center">
                <div class="td">
                  <el-checkbox
                    v-model="item.checked"
                    :key="item.id"
                    @change="changeCheckBoxHandle($event, item)"
                  >{{i+1}}</el-checkbox>
                </div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.on}} > {{item.tn}}</div>
                <div class="td">{{item.p}}</div>
                <div class="td">{{item.pt}}</div>
                <div class="td">{{item.bt}}</div>
                <div class="td">{{item.s == 1 ? '有效' : '无效'}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
            <div v-if="tableData.length > 0" class="tips p-t-2 p-b-2" style="text-align:center">{{loadingText}}</div>
          </div>
        </div>

      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" style="background:#2170ff" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      cateVal: 0,
      cateOptions: [],
      keyword: '',
      tableData: [],
      loadingText: '加载中...',

      pageInfo: {
        page: 1,
        pageSize: 20
      }
    };
  },
  methods: {
    async getPrdCategoryAndPrdList(isInit = 0){
      this.pageInfo.page = isInit == 1 ? 1 : this.pageInfo.page + 1
      const params = {
        name: this.keyword.toString(), //      string  关键字
        page_num: this.pageInfo.page * 1, //  int   页码
        page_size: this.pageInfo.pageSize, //  int    每页显示数量
        is_init: isInit * 1, //    int     是否初始化 1:初始化
        one_cate_id: this.cateVal[0], // int64   一级分类
        two_cate_id: this.cateVal[1] // int64   二级分类
      }
      try {
        const res = await this.$api.BMS.region.reqGetPrdCateAndPrdList(params);
        if (res.code == 1) {
          if (isInit == 1) {
            const cateOptions = res.data.cates || [];
            cateOptions.forEach(el => {
              el.value = el.id;
              el.label = el.n;
              if (el.ss) {
                el.ss.forEach(ele => {
                  ele.value = ele.id;
                  ele.label = ele.n;
                });
                el.children = el.ss;
              }
            });

            this.cateOptions = cateOptions;
          }
          const tableData = res.data.items || [];

          this.loadingText = tableData.length == this.pageInfo.pageSize ? "加载中..." : "没有更多数据了";

          this.tableData =
            isInit == 1
              ? tableData.map(item => ({
                  ...item,
                  // checked: item.id == this.currentInfo.id
                    checked:false,
                }))
              : [
                  ...this.tableData,
                  ...tableData.map(item => ({
                    ...item,
                    // checked: item.id == this.currentInfo.id
                    checked:false,
                  }))
                ];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取相关数据失败", error);
      }
    },
    
    changeCheckBoxHandle(e, itemInfo){
      // // this.tableData = this.tableData.map(item => ({
      // //   ...item,
      // //   checked: item.id == itemInfo.id
      // // }))
      // console.log(e)
      // console.log("itemInfo checked:", itemInfo.checked)
      // // for(let item of this.tableData){
      // //   if(item.id === itemInfo.id){
      // //     item.checked = !item.checked
      // //     break
      // //   }
      // // }
      // console.log(this.tableData)
      // this.tableData = [...this.tableData]
    },

    onSubmit() {
      const prdInfo = this.tableData.filter(item => item.checked)
      if(prdInfo && prdInfo.length > 0 ){
        if(prdInfo.length > 3){
          this.$message.warning('最多选择三个商品')
          return
        }
        this.$emit('getChoosePrdHandle', prdInfo)
        this.onCancelDrawer()
      } else {
        this.$message.warning('请选择商品')
      }
    },
    resetSelectHandle (){
      this.pageInfo.page = 1
      this.cateVal = 0
      this.keyword = ''
      this.getPrdCategoryAndPrdList(1)
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
    currentInfo: {
      default: () => ([])
    }
  },
  computed: {
    title() {
      return this.currentInfo.length > 0 ? "编辑商品" : "添加商品";
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
          this.resetSelectHandle()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
@import "../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.table {
  height: calc(100vh - 240px);
  overflow: auto;
  .th,.td {
    &:nth-child(1),
    &:nth-child(4),
    &:nth-child(5),
    &:nth-child(6),
    &:nth-child(7){
      width: 30%;
    }
  }
}
</style>