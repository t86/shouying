<template>
  <div class="seal-prd-config p-5">
   <p class="red-color fs14">说明：请选择需要在收银系统统计售卖情况的商品</p>
  <div class="config m-t-3" layout="row" layout-align="space-between start">
    <div class="left">
      <!-- 头部筛选项 -->
      <div class="select-top" layout="row" layout-align="start center">
        <div class="item" layout="row" layout-align="start center">
          <div class="label fs14">分类：</div>
          <el-cascader
            style="width:150px"
            v-model="searchFormData.valueArr"
            :options="searchFormData.options"
            size="mini"
            clearable
          ></el-cascader>
        </div>
        <div class="item m-r-2 m-l-2" layout="row" layout-align="start center">
          <el-input
            v-model="searchFormData.keyword"
            style="width: 120px"
            size="mini"
            placeholder="商品名称/拼音"
          ></el-input>
        </div>
        <div class="item" layout="row" layout-align="start center">
          <el-button type="primary" size="mini" style="background:#2170ff" @click.stop="getTableData(1)">查询</el-button>
          <el-button type="info" size="mini" @click.stop="restSearchData">重置</el-button>
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
              <div class="th">商品名称</div>
              <div class="th">一级分类</div>
              <div class="th">二级分类</div>
              <div class="th">单价</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item, index) in tableData"
              :key="index"
              layout="row"
              layout-align="space-between center"
              :class="{'gray': item.disabled}"
            >
              <div class="td">
                <el-checkbox v-model="item.checked"
                  :disabled="item.disabled" 
                  @change="changeCheckboxHandle('item')"
                  >{{ index + 1 }}
                </el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.on}}</div>
              <div class="td">{{item.tn}}</div>
              <div class="td">{{item.price}}</div>
            </div>
            <div class="no-data m-t-10" v-if="tableData.length == 0" style="text-align:center">
              <img src="@/assets/img/wu.png" style="width:60px" alt />
              <p class="m-t-2 fs12">暂无数据</p>
            </div>
            <div class="tips p-t-2 fs14" style="text-align:center" v-if="tableData.length > 0">{{isLoaded ? '没有更多了' : '加载中...' }}</div>
          </div>
        </div>
      </div>
    </div>
    <div class="center">
      <el-button style="margin-top: 200px" type="primary" size="small" @click="addPrdHandle">添加>></el-button>
    </div>
    <div class="right">
      <!-- table -->
      <div class="table-content" style="margin-top:36px">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">序号</div>
              <div class="th">商品名称</div>
              <div class="th">一级分类</div>
              <div class="th">二级分类</div>
              <div class="th">单价</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item, index) in tableDataRight"
              :key="index"
              layout="row"
              layout-align="space-between center"
            >
              <div class="td">{{index + 1}}</div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.on}}</div>
              <div class="td">{{item.tn}}</div>
              <div class="td">{{item.price}}</div>
              <div class="td">
                <span class="primary-link cursor" @click="deleteHandle(item)">删除</span>
              </div>
            </div>
            <div class="no-data m-t-10" v-if="tableDataRight.length == 0" style="text-align:center">
              <img src="@/assets/img/wu.png" style="width:60px" alt />
              <p class="m-t-2 fs14">暂无数据</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
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
        },

        tableDataRight: []
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
          init: init,
          one_cate_id: this.searchFormData.valueArr[0] * 1,
          two_cate_id: this.searchFormData.valueArr[1] * 1
        };

        try {
          const res = await this.$api.BMS.reportConfig.reqGetSealPrdList(params);
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
            const tableData = (res.data.prds || []).map(item => ({
              ...item,
              checked: false,
              disabled: !!this.tableDataRight.find(items => items.id == item.id)
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
              checked: item.disabled ? false : this.checkAll
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
      
      // 重置
      restSearchData() {
        this.searchFormData.valueArr = [0, 0];
        this.searchFormData.keyword = "";
        this.isLoaded = false
        this.getTableData(1);
      },

      // 获取服务员销售商品
      async getRightTableData(){
        try {
          const res = await this.$api.BMS.reportConfig.reqGetFXYSealPrdList();
          if(res.code == 1) {
            this.tableDataRight = res.data.records || []
            
            this.getTableData(1)
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('服务员销售商品数据请求失败', error);
        }
      },

      async addPrdHandle(){
        const params = {
          prd_ids: this.tableData.filter(item => item.checked).map(item => item.id * 1) //  []int64   待添加商品列表
        }
        if(params.prd_ids.length <= 0) return this.$message.warning('请选择需要添加的商品')
        try {
          const res = await this.$api.BMS.reportConfig.reqAddFXYSealPrds(params);
          if(res.code == 1) {
            this.getRightTableData()
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('添加商品请求失败', error);
        }
      },

      // 删除
      async deleteHandle(itemInfo){
        const params = {
          prd_id: itemInfo.id * 1 // int64    待删除商品Id
        }
        try {
          const res = await this.$api.BMS.reportConfig.reqDelFXYSealPrd(params);
          if(res.code == 1) {
            this.getRightTableData()
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      }
    },

    created() {
      this.getRightTableData()
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
  }
 
</script>

<style lang="less" scoped>
@import '../../../../style/erp/table.less';
</style>

<style scoped lang='less'>
.seal-prd-config {
  height: calc(100vh - 110px);
  overflow: auto;
  .tips {
    line-height: 26px;
  }
  .left,.right {
    width: 40%;
    .table-content {
      border: 1px solid #f9f9f9;
      max-height: calc(100vh - 200px);
      overflow: auto;

      .td,.th {
        &:nth-child(1) {
          width: 30%;
        }
      }
    }
  }
  .center {
    width: 15%;
    text-align: center;
  }

  .right {
    width: 45%;
  }
}
</style>