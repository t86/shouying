<template>
  <div>
    <!-- 套餐组添加商品 -->
   <el-drawer
     :title='title'
     :visible.sync='show'
     :before-close='onCancelDrawer'
     direction='rtl'
     append-to-body
     size='90%'
   >
    <div class='session p-5 fs14'>
      <!-- 头部筛选项 -->
      <div class="select-top" layout="row" layout-align="start center">
        <div class="item" layout="row" layout-align="start center">
          <div class="label">分类：</div>
          <el-cascader
            v-model="searchFormData.valueArr"
            :options="searchFormData.options"
            size="small"
            clearable
          ></el-cascader>
        </div>
        <div class="item" layout="row" layout-align="start center">
          <el-input
            v-model="searchFormData.keyword"
            style="width: 200px"
            size="small"
            placeholder="请输入商品名称 模糊查询"
          ></el-input>
        </div>
        <div class="item" layout="row" layout-align="start center">
          <el-button type="primary" style="background:#2170ff" @click.stop="getTableData(1)">查询</el-button>
          <el-button type="info" @click.stop="restSearchData">重置</el-button>
        </div>
      </div>
      <!-- table -->
      <div class="table-content m-t-3">
        <div class="table" v-infinite-scroll="loadNextPageHandle">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">
                <el-checkbox
                  v-model="checkAll"
                  :indeterminate="isIndeterminate"
                  @change="changeCheckboxHandle('all')"
                >全选</el-checkbox>
              </div>
              <div class="th">单品名称</div>
              <div class="th">分类</div>
              <div class="th">单价</div>
              <div class="th">存货商品名</div>
              <div class="th">类型</div>
              <div class="th">营业类型</div>
              <div class="th">状态</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item, index) in tableData"
              :key="index"
              layout="row"
              layout-align="space-between center"
            >
              <div class="td">
                <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{ index + 1 }}</el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.on}} > {{item.tn}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.mn}}</div>
              <div class="td">{{item.pt}}</div>
              <div class="td">{{item.bt}}</div>
              <div class="td">{{item.s==1?'有效':'无效'}}</div>
            </div>
            <div class="no-data m-t-10" v-if="tableData.length == 0" style="text-align:center">
              <img src="@/assets/img/wu.png" style="width:60px" alt />
              <p class="m-t-2">暂无数据</p>
            </div>
            <div class="tips p-t-2" style="text-align:center" v-if="tableData.length > 0">{{isLoaded ? '没有更多了' : '加载中...' }}</div>
          </div>
        </div>
      </div>
    </div>
    <div class='form-btn' layout='row' layout-align='center center'>
      <el-button type='info' @click='onCancelDrawer'>关闭</el-button>
      <el-button type='primary' style="background:#2170ff" @click='onSubmit'>确定</el-button>
    </div>
    </el-drawer>
  </div>
</template>
 
<script>
  export default {
    data() {
      return {
        isLoaded: false, // 分页是否加载完成
        // 筛选条件
        searchFormData: {
          valueArr: [0, 0],
          options: [],
          keyword: ""
        },
        tableData: [],
        checkAll: false,

        pageInfo: {
          page: 1,
          pageSize: 20,
          total: 0
        }
      }
    },
    methods: {
       // 获取表格数据
      async getTableData(init = 2) {
        if(init == 1) {
          this.pageInfo.page = 1
          this.isLoaded = false
        }
        if(this.isLoaded) return
        const params = {
          name: this.searchFormData.keyword,
          page_num: this.pageInfo.page,
          page_size: this.pageInfo.pageSize,
          is_init: init,
          one_cate_id: this.searchFormData.valueArr[0] * 1,
          two_cate_id: this.searchFormData.valueArr[1] * 1
        };

        try {
          const res = await this.$api.BMS.Prd.requestprdget_set_items(params);
          if (res.code == 1) {
            if (init == 1) {
              const options = res.data.cates || [];
              options.forEach(el => {
                el.value = el.id
                el.label = el.n
                el.children =
                  el.ss && el.ss.length > 0
                    ? JSON.parse(JSON.stringify(el.ss))
                    : []

                el.children.forEach(ele => {
                  ele.value = ele.id
                  ele.label = ele.n
                });
              });

              this.searchFormData.options = [...options]
            }
            const tableData = (res.data.items || []).map(item => ({
              ...item,
              checked: false
            }));

            this.tableData = init == 1 ? [...tableData] : [...this.tableData, ...tableData]

            this.checkAll = this.tableData.every(item => item.checked)

            this.isLoaded = this.tableData.length < this.pageInfo.pageSize * this.pageInfo.page
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log("获取商品列表失败", error)
        }
      },

      changeCheckboxHandle(type) {
        switch (type) {
          case "all":
            this.tableData = this.tableData.map(item => ({
              ...item,
              checked: this.checkAll
            }));
            break;
          case "item":
            this.checkAll = this.tableData.every(item => item.checked);
            break;
        }
      },

      // 加载下一页
      loadNextPageHandle(){
        this.pageInfo.page = this.pageInfo.page + 1
        this.getTableData()
      },

      async onSubmit() {
        this.$emit('changePrdList', this.tableData.filter(item => item.checked))
        this.onCancelDrawer()
      },
      
      // 重置
      restSearchData() {
        this.searchFormData.valueArr = [0, 0];
        this.searchFormData.keyword = "";
        this.isLoaded = false
        this.getTableData(1);
      },

      onCancelDrawer() {
        this.show = false
      }
    },
    created() {
 
    },
    mounted() {
 
    },
    props: {
      value: {
        default: false
      }
    },
    computed: {
      title() {
        return '新增套餐单品'
      },
      show: {
        get() {
          return this.value
        },
        set(val) {
          this.$emit('input', val)
        }
      },
      isIndeterminate() {
        return !this.checkAll && this.tableData.some(item => item.checked);
      }
    },
    watch: {
      value: {
        handler(newVal) {
          if (newVal) {
            this.tableData = []
            this.getTableData(1);
          }
        },
        immediate: true
     }
   }
 }
 
</script>

<style scoped lang='less'>
@import '../../../../../../style/common/elementDrawerWine.less';
@import '../../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../../style/erp/form.less';
@import '../../../../../../style/erp/table.less';
</style>
<style scoped lang='less'>

.select-top{
  flex-wrap: wrap;

    .item {
      margin: 4px 20px 4px 0;
    }
}

.table{
  height: calc(100vh - 220px);
  overflow-y: auto;
  .th,.td {
    &:nth-child(1),
    &:nth-child(4),
    &:nth-child(6),
    &:nth-child(7),
    &:nth-child(8) {
      width: 30%;
    }
  }
}

/deep/.el-input__inner{
  background-color: transparent!important;
  color: #40404e!important;
}

// 分类选择框icon
/deep/.el-cascader .el-input .el-icon-arrow-down{
  transform-origin: center 20px;
}
</style>