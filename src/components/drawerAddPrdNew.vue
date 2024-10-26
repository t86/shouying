<template>
  <div>
    <!-- 添加商品 -->
    <el-drawer
      title="新增商品"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="85%"
    >
      <div class="flex">
        <!-- 商品列表 -->
        <div class="session p-4 w-45 border-dashed">
          <!-- 头部筛选项 -->
          <div class="select-top fs14" layout="row" layout-align="start center">
            <div class="item" layout="row" layout-align="start center">
              <div class="label">分类：</div>
              <el-cascader
                  v-model="searchFormData.valueArr"
                  size="mini"
                  :options="searchFormData.options"
                  clearable
              ></el-cascader>
            </div>
            <div class="item" layout="row" layout-align="start center">
              <el-input
                  v-model="searchFormData.keyword"
                  size="mini"
                  style="width: 200px"
                  placeholder="请输入商品名称或编码"
              ></el-input>
            </div>
            <div class="item" layout="row" layout-align="start center">
              <el-button type="primary" style="background-color: #2170ff" size="mini" @click.stop="getTableData(1)">查询</el-button>
              <el-button type size="mini" @click.stop="restSearchData">重置</el-button>
            </div>
          </div>
          <!-- table -->
          <div class="table-content">
            <div class="table" v-infinite-scroll="getTableData">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">
                    <el-checkbox
                        v-model="checkAll"
                        :indeterminate="isIndeterminate"
                        @change="changeCheckbox('all')"
                    >全选</el-checkbox></div>
                  <div class="th">名称</div>
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
                    <el-checkbox
                        :disabled="item.disabled"
                        v-model="item.checked"
                        @change="changeCheckbox('item')"
                    >{{ index + 1 }}</el-checkbox>
                  </div>
                  <div class="td">{{ item.n }}</div>
                  <div class="td">{{ item.on }} > {{item.tn}}</div>
                  <div class="td">{{ item.p }}</div>
                  <div class="td">{{ item.mn }}</div>
                  <div class="td">{{ item.pt }}</div>
                  <div class="td">{{ item.bt }}</div>
                  <div class="td">{{ item.s===1 ? '有效': '无效' }}</div>
                </div>
                <div class="no-data" v-if="tableData.length==0">
                  <img :src="require('@/assets/img/wu.png')" alt />
                  <p>暂无数据</p>
                </div>
              </div>
              <p class="m-t-3 fs12" style="text-align:center">{{loadText}}</p>
            </div>
          </div>
        </div>

        <!-- 右箭头按钮 -->
        <div class="session p-4 w-10">
          <el-button type="primary" icon="el-icon-arrow-right" @click="addSelectedItems"></el-button>
        </div>

        <!-- 已选列表 -->
        <div class="session p-4 w-45 border-dashed">
          <div class="select-top fs14" layout="row" layout-align="start center">
            <div class="item" layout="row" layout-align="start center">
              <div class="label">已选列表</div>
            </div>
          </div>
          <div class="table-content">
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">序号</div>
                  <div class="th">名称</div>
                  <div class="th">分类</div>
                  <div class="th">操作</div>
                </div>
              </div>
              <div class="tbody">
                <div
                    class="tr"
                    v-for="(item, index) in selected"
                    :key="index"
                    layout="row"
                    layout-align="space-between center"
                >
                  <div class="td">{{ index + 1 }}</div>
                  <div class="td">{{ item.n }}</div>
                  <div class="td">{{ item.on }} > {{item.tn}}</div>
                  <div class="td">
                    <el-button type="text" size="small" @click="removeSelected(item)">删除</el-button>
                  </div>
                </div>
                <div class="no-data" v-if="selected.length==0">
                  <img :src="require('@/assets/img/wu.png')" alt />
                  <p>暂无数据</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click.stop="onCancelDrawer">关闭</el-button>
        <el-button type="primary" style="background-color: #2170ff" @click.stop="submit">确定</el-button>
      </div>


    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      // 筛选条件
      searchFormData: {
        valueArr: [0, 0],
        options: [],
        keyword: ""
      },
      checkAll: false,
      tableData: [],
      selected:[],
      loadText: '',
      pageSize: 50,
      page: 1,
    };
  },
  methods: {
    submit(){
      this.onCancelDrawer();
      this.$emit("selectedPrds", this.selected);
    },
    // 获取商品分类
    async getTableData(init = 2) {
      if (this.loadText === '没有更多了' && init !== 1) {
        return;
      }
      
      this.page = init == 1 ? 1 : this.page + 1
      const params = {
        page_num: this.page,
        page_size: this.pageSize,
        init: init,
        is_init: init,
        name: this.searchFormData.keyword || "",
        one_cate_id: this.searchFormData.valueArr[0],
        two_cate_id: this.searchFormData.valueArr[1],
      };
      try {
        let res = await this.$api.BMS.Prd.requestprdget_set_items(params);
        if (res.code == 1) {
          if (init == 1) {
            const options = res.data.cates || [];
            options.forEach(el => {
              el.value = el.id;
              el.label = el.n;
              el.children =
                el.ss && el.ss.length > 0
                  ? JSON.parse(JSON.stringify(el.ss))
                  : [];

              el.children.forEach(ele => {
                ele.value = ele.id;
                ele.label = ele.n;
              });
            });
            this.searchFormData.options = [...options];
          }
          const tableData = (res.data.items|| []).map(item =>
            { 
              let matched = this.checkedPrdList.findIndex(i => i.id == item.id) >= 0;
              return {
                ...item,
                checked: matched,
                disabled: matched,
                count: 1
              }
          })
          this.loadText = tableData.length == this.pageSize ? '加载中...' : '没有更多了'
          this.tableData = init == 1 ? [...tableData] : [...this.tableData, ...tableData]
          this.checkAll = this.tableData.every(item => item.checked)
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("", error);
      }
    },

    changeCheckbox(type){
      switch(type) {
        case 'all':
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }))
          break
        case 'item':
          this.checkAll = this.tableData.every(item => item.checked)
          break
      }
      // // 更新 selected 数组
      // const selectedMap = new Map(this.selected.map(item => [item.id, item]));
      // this.tableData.forEach(item => {
      //   if (item.checked) {
      //     selectedMap.set(item.id, item);
      //   } else {
      //     selectedMap.delete(item.id);
      //   }
      // });
      // this.selected = Array.from(selectedMap.values());
    },

    // 重置
    restSearchData() {
      this.searchFormData.valueArr = [0, 0];
      this.searchFormData.keyword = "";
      this.getTableData();
    },
    // 关闭drawer
    onCancelDrawer() {
      this.show = false
    },

    removeSelected(item) {
      // 从 selected 数组中��除项目
      this.selected = this.selected.filter(i => i.id !== item.id);
      
      // 更新 tableData 中对应项目的 checked 状态
      const tableItem = this.tableData.find(i => i.id === item.id);
      if (tableItem) {
        tableItem.checked = false;
      }
      
      // 更新 checkAll 状态
      this.checkAll = this.tableData.every(item => item.checked);
    },

    addSelectedItems() {
      const newSelectedItems = this.tableData.filter(item => item.checked);
      const selectedMap = new Map(this.selected.map(item => [item.id, item]));
      
      newSelectedItems.forEach(item => {
        selectedMap.set(item.id, item);
        // item.disabled = true;
      });

      this.selected = Array.from(selectedMap.values());
      this.checkAll = this.tableData.every(item => item.checked);
    },
  },
  props: {
    value: {
      default: false // 是否显示drawer
    },
    checkedPrdList: {
      default: []
    },
  },
  computed: {
    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    isIndeterminate(){
      return !this.checkAll && this.tableData.some(item => item.checked)
    }
  },
  watch: {
    value(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getTableData(1);
      } else {
        this.tableData = []
        this.searchFormData.keyword = ''
        this.searchFormData.valueArr = [0, 0]
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../style/common/elementDrawerWine.less";
@import "../style/common/elementDrawerHeaderAndSession.less";
@import "../style/common/elementFormBtnWine.less";
@import "../style/erp/form.less";
@import "../style/erp/table.less";
</style>
<style scoped lang="less">
.select-top {
  flex-wrap: wrap;

  .item {
    margin: 4px 20px 4px 0;
  }
}

.table {
  max-height: calc(100vh - 200px);
  overflow-y: auto;
  .th,.td {
    &:nth-child(1),
    &:nth-child(4){
      width: 20%;
    }
    &:nth-child(2),
    &:nth-child(3){
      width: 30%;
    }
  }
}

.flex {
  display: flex;
}

.items-center {
  align-items: center;
}

.justify-center {
  justify-content: center;
}

.w-45 {
  width: 45%;
}

.w-10 {
  text-align: center;
  width: 80px;
}
</style>

<style>
.el-icon-arrow-right:before {
  color: #606266;
}
</style>
