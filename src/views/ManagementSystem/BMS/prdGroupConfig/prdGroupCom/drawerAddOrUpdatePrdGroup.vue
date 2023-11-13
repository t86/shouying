<template>
  <div>
    <!-- 新增或修改商品管理组 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
      append-to-body
    >
      <div class="session p-5 fs14">
        <div class="coll p-b-3 border-bottom" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">商品组名称：</span>
          </div>
          <div class="value">
            <el-input v-model="prdGroupName" size="small" @input="validator" placeholder="请输入商品组名称"></el-input>
          </div>
        </div>

        <div class="coll p-b-3 border-bottom" layout="row" layout-align="start start">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs18">包含</span>
            <span class="fs14">二级分类：</span>
          </div>
          <div class="value">
            <el-tree
              node-key="id"
              :data="treeData"
              show-checkbox
              :props="defaultProps"
              @check="clickTreeCheckBox"
              :default-checked-keys="selectList"
            ></el-tree>
          </div>
        </div>

        <div class="coll p-b-3 border-bottom">
          <div class="label p-l-6" style="width:100%;text-align:left;">
            <span class="red-color">*</span>
            <span class="fs18">包含</span>
            <span class="fs14">特定商品：</span>
            <span class="red-color fs12">说明：选择除去上面所选二级分类下的商品外，该商品组还包含的商品</span>
          </div>
          <div class="value m-t-3 m-l-8">
            <el-button type="primary" size="small" @click.native="showAddPrdDrawer = true">新增商品</el-button>
            <el-button type="primary" size="small" @click.native="deleteHandle">批量删除</el-button>
          </div>
        </div>

        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="checkAll"
                    :indeterminate="isIndeterminate"
                    @change="changeCheckboxHandle('all')"
                  >全选</el-checkbox>
                </div>
                <div class="th">单品</div>
                <div class="th">分类</div>
                <div class="th">单价</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                v-for="(item, index) in tableData"
                :key="item.id"
                layout="row"
                layout-align="space-between center"
              >
                <div class="td">
                  <el-checkbox
                    v-model="item.checked"
                    @change="changeCheckboxHandle('item')"
                  >{{index + 1}}</el-checkbox>
                </div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.on}}</div>
                <div class="td">{{item.price}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 添加商品 -->
      <drawerAddPrd v-model="showAddPrdDrawer" @getChoosedPrdList="getChoosedPrdList" />

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      prdGroupName: "",
      treeData: [], //选择二级列表全部内容
      selectList: [], // 默认选中节点
      checkedTwoCate: [], // 选中的二级分类
      
      prdList: [], // 商品组包含的商品
      defaultProps: {
        children: "ts",
        label: "n"
      },

      tableData: [],
      checkAll: false,
      showAddPrdDrawer: false
    };
  },
  methods: {
    init() {
      this.prdGroupName = ""
      this.selectList = []
      this.checkedTwoCate = []
      this.prdList = []
      this.type == 1 ? this.getTreeData() : this.getDetailInfo()
    },

    async getTreeData() {
      const params = {
        id: 0
      };
      try {
        const res = await this.$api.BMS.pgrp.requestpgrpget(params);
        if (res.code == 1) {
          let s = res.data.cates;
          for (let i = 0; i < s.length; i++) {
            if (s[i].ts == null) {
              s.splice(i, 1);
              i -= 1;
            }
          }
          this.treeData = [
            {
              n: "以下全部",
              ts: s
            }
          ];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    async getDetailInfo(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.BMS.pgrp.requestpgrpget(params)
        if(res.code == 1) {
          let s = res.data.cates
            for (let i = 0; i < s.length; i++) {
              if (s[i].ts == null) {
                s.splice(i, 1)
                i -= 1
              }
            }
            this.treeData = [{
              n: '以下全部',
              ts: s,
            }]
            let w = []
            for (const item of s) {
              for (const items of item.ts) {
                if (items.s == 1) {
                  w.push(items.id)
                }
              }
            }
            this.prdGroupName = res.data.name || ''
            this.tableData = (res.data.prds || []).map(item => ({
              ...item,
              checked: true
            }))
            this.checkAll = true
            this.selectList = w
            this.checkedTwoCate = w
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    getChoosedPrdList(prdList){
      this.tableData = [...this.tableData, ...prdList].filter((item, index, arr) => arr.findIndex(items => items.id == item.id) == index)
      this.checkAll = this.tableData.every(item => item.checked)
    },

    // 删除
    deleteHandle() {
      const checkedIdList = this.tableData.filter(item => item.checked).map(item => item.id)
      const tableData = []
      this.tableData.forEach(el => {
        if(!checkedIdList.find(item => item == el.id)) tableData.push(el)
      })
      this.tableData = [...tableData]
      this.checkAll = false
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

    validator() {
      if (this.prdGroupName == "") {
        this.$message.warning("请输入商品组名称");
      } else if (this.$overall.character(this.prdGroupName) > 20) {
        this.$message.warning("输入文字长度超过10");
      }
    },

    // 选中的二级分类
    clickTreeCheckBox(nodeObj, SelectedObj) {
      const checkedTwoCate = [];
      for (const item of SelectedObj.checkedKeys) {
        if (item != undefined) {
          checkedTwoCate.push(item);
        }
      }
      this.checkedTwoCate = [...checkedTwoCate];
    },

    async onSubmit() {
      if(this.prdGroupName == '') return this.$message.warning('请输入商品组名称')
      const params = {
        name: this.prdGroupName || '',
        prd_ids: this.tableData.map(item => item.id * 1),
        cate_ids: this.checkedTwoCate,
        ...this.type == 2 && {id: this.currentInfo.id}
      };
      try {
        const api = this.type == 1 ? 'requestpgrpnew' : 'requestpgrpsave'
        const res = await this.$api.BMS.pgrp[api](params);
        if (res.code == 1) {
          this.$message.success(this.type == 1 ? '创建成功' : '编辑成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("请求失败", error);
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
    type: {
      default: 1
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增商品组" : "编辑商品组";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  components: {
    drawerAddPrd: () => import('./drawerAddPrd.vue')
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.init();
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
@import "../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  .label {
    width: 150px;
    text-align: right;
  }

  &.border-bottom {
    border-bottom: 1px dashed #999;
  }
}

.table-content {
  .table {
    .th,.td {
      &:nth-child(1) ,
      &:nth-child(4) {
        width: 30%;
      }
      &:nth-child(2) {
        width: 70%;
      }
    }
  }
}
</style>