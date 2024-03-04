<template>
  <div>
    <div class="warning">
      说明：未在表单中配置规则的商品, 不能使用当前会员卡结账！
    </div>
    <!-- 现有功能内容继续 -->
    <div class="search m-t-2 m-b-4">
      <div class="row">
        <span class="label">商品分类:</span>
        <el-cascader
          clearable
          size="small"
          :options="cateOptions"
          v-model="cateVal"
        ></el-cascader>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <el-input
          class="m-r-2"
          v-model="keyword"
          size="small"
          placeholder="商品名称/首字母"
          style="width: 200px"
        ></el-input>
        <button
          class="btn primary m-l-4"
          @click="() => this.getTableData(false)"
        >
          查询
        </button>
        <button class="btn info m-l-4" @click="resetHandle">重置</button>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <span class="label m-r-1">商品规则:</span>
        <el-select
          v-model="ruleVal"
          size="small"
          placeholder="请选择商品规则"
          style="width: 200px"
        >
          <el-option
            v-for="item in ruleOptions"
            :key="item.id"
            :label="item.name"
            :value="item.id"
          >
          </el-option>
        </el-select>
      </div>
      <div></div>
      <div
        class="row m-t-4"
        layout="row"
        layout-align="start center"
        style="width: 500px"
        v-if="$store.getters.vipAuth"
      >
        <button class="btn primary" @click="showOrHideDrawerHandle">
          新增
        </button>
        <button class="btn primary m-l-4" @click="batchDelete">
          批量删除
        </button>
        <button class="btn primary large m-l-4" @click="batchChange">
          批量更改扣款规则
        </button>
        <button class="btn primary large m-l-4" @click="copy">
          复制结账配置
        </button>
      </div>
    </div>

    <div class="contain">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checked"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
                >序号</el-checkbox
              >
            </div>
            <div class="th">卡等级</div>
            <div class="th">商品名称</div>
            <div class="th">一级分类</div>
            <div class="th">二级分类</div>
            <div class="th">单价</div>
            <div class="th">商品类型</div>
            <div class="th">扣款规则</div>
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
                :value="item.checked"
                @change="changeCheckboxHandle('item', item.id)"
                >{{ index + 1 }}</el-checkbox
              >
            </div>
            <div class="td">{{ item.l }}</div>
            <div class="td">{{ item.n }}</div>
            <div class="td">
              {{ cateOptions.find((i) => i.id == item.oc).n }}
            </div>
            <div class="td">
              {{
                cateOptions
                  .find((i) => i.id == item.oc)
                  .children.find((i) => (i.id = item.tc)).n
              }}
            </div>
            <div class="td">{{ item.p }}</div>
            <div class="td">{{ item.t }}</div>
            <div class="td" layout="row" layout-align="start center">
              <span>{{ item.tn }}</span>
            </div>

            <div
              class="sj"
              v-if="item.showTips"
              :style="{ left: item.pointerX - 20 + 'px' }"
            ></div>
            <ul
              class="tips"
              v-if="item.showTips"
              :style="{
                left: item.pointerX + 65 + 'px',
                transform: 'translate(-50%,' + item.disY * -1 + 'px)',
              }"
            >
              <li
                class="item"
                v-for="items in item.tipsList"
                :key="items.id"
                @click="clickOptionHandle(item, items)"
              >
                <div>{{ items.name }}</div>
              </li>
            </ul>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img :src="require('@/assets/vip-imgs/empty.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <div class="pagination">
      <el-pagination
        background
        layout="prev, pager, next"
        :total="pageInfo.total"
        :page-size="pageInfo.pageSize"
        :current-page="pageInfo.page"
        @current-change="changePageHandle"
      >
      </el-pagination>
    </div>

    <drawerAddRuleCom
      :item="item"
      :showDrawer="showAddDrawer"
      :addedSeatList="tableData"
      @showOrHideDrawerHandle="showOrHideDrawerHandle"
      @getTableData="refresh"
    />
    <drawerUpdateRuleCom
      :item="item"
      :showDrawer="showUpdateDrawer"
      :addedSeatList="tableData"
      @showOrHideDrawerHandle="showOrHideUpdateDrawerHandle"
      @getTableData="refresh"
    />

    <drawerCopyCom
      :item="item"
      :showDrawer="showCopyDrawer"
      @showOrHideCopyDrawerHandle="showOrHideCopyDrawerHandle"
      @getTableData="refresh"
    />
  </div>
</template>


<script>
import api_vip from "@/api/vip";
import drawerAddRuleCom from "../../../views/vip/drawerRuleCom/drawerAddRuleCom.vue";
import drawerUpdateRuleCom from "../../../views/vip/drawerRuleCom/drawerUpdateRuleCom.vue";
import drawerCopyCom from "../../../views/vip/drawerRuleCom/drawerCopyRuleCom.vue";
export default {
  components: {
    drawerAddRuleCom,
    drawerUpdateRuleCom,
    drawerCopyCom,
  },
  props: {
    item: {},
    activeTab: {
      type: String,
      default: "billRules",
    },
  },
  watch: {
  },
  computed: {
    title() {
      return "配置";
    },
    isIndeterminate() {
      if (
        this.tableData
          .filter((item) => !item.disabled)
          .every((item) => item.checked)
      ) {
        return false;
      } else {
        return this.tableData.some((item) => item.checked);
      }
    },
  },
  data() {
    return {
      show: {
        default: false,
      },
      cateOptions: [],
      cateVal: [],
      checked: false,
      keyword: "",
      tableData: [],
      showAddDrawer: false,
      showUpdateDrawer: false,
      showCopyDrawer: false,
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },
      init: false,
      ruleVal: 0,
      ruleOptions: [
        {
          id: 0,
          name: "全部",
        },
        {
          id: 1,
          name: "按比例扣款",
        },
        {
          id: 2,
          name: "先用赠送金额",
        },
        {
          id: 3,
          name: "只能用值金额",
        },
        {
          id: 4,
          name: "只用赠送金额",
        },
      ],
    };
  },
  methods: {
    async getTableData(rest = false) {
      if (rest) this.pageInfo.page = 1;
      const params = {
        page_num: this.pageInfo.page, //   int   第几页
        page_size: this.pageInfo.pageSize, //  int     每页行数
        init: rest ? 1 : 2, //    int    初始化标记 1 初始化, 会返回一级分类的结构    2 非初始化, 不返回一级分类结构
        one_cate_id: this.cateVal[0] || 0, // string   一级分类id =0 代表不限制
        two_cate_id: this.cateVal[1] || 0, // string 二级分类id =0 代表不限制
        name: this.keyword,
        card_type_id: this.item.id,
        type_id: this.ruleVal,
      };
      try {
        let res = await api_vip.reqGetVipBillRuleList(params);
        if (res.code == 1) {
          if (rest) {
            const cateOptions = res.data.cates || [];
            cateOptions.forEach((el) => {
              el.value = el.id;
              el.label = el.n;
              if (el.ss) {
                el.ss.forEach((ele) => {
                  ele.value = ele.id;
                  ele.label = ele.n;
                });
                el.children = el.ss;
              }
            });

            this.cateOptions = cateOptions;
          }

          this.pageInfo.total = 1;
          this.tableData =
            (res.data.records &&
              res.data.records.map((d) => {
                d.checked = false;
                return d;
              })) ||
            [];
          this.$forceUpdate();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("会员结账规则数据获取失败", error);
      }
    },
    // 改变多选框的值
    changeCheckboxHandle(type, itemId) {
      switch (type) {
        case "all":
          this.tableData.forEach((el) => {
            if (!el.disabled) el.checked = this.checked;
          });
          break;
        case "item":
          this.tableData.forEach((el) => {
            if (el.id == itemId) {
              el.checked = !el.checked;
            }
          });
          this.checked = this.tableData
            .filter((item) => !item.disabled)
            .every((item) => item.checked);
          break;
      }
      this.$forceUpdate();
    },
    resetHandle() {
      this.productVal = [];
      this.productOption = "";
      this.keyword = "";
      this.checked = false;
      this.cateVal = [];
      this.ruleVal = 0;
      this.getTableData(true);
    },
    async batchDelete() {
      const params = {
        prd_ids: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.id * 1), //   []int64  待删除商品列表
        card_type_id: this.item.id, //CardTypeId 会员卡类型Id
      };
      if (params.prd_ids.length == 0)
        return this.$message.warning("请选择需要删除的商品");
      try {
        const res = await api_vip.reqDelVipBillRule(params);
        if (res.code == 1) {
          this.$message.success("删除成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("批量删除商品失败", error);
      }
    },
    batchChange() {
      const params = {
        prd_ids: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.id * 1), //   []int64  待删除商品列表
      };
      if (params.prd_ids.length == 0)
        return this.$message.warning("请选择需要批量操作的商品");
      this.showOrHideUpdateDrawerHandle();
    },
    copy() {
      // 点击弹窗选复制的会员卡类型
      this.showOrHideCopyDrawerHandle();
    },
    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },
    showOrHideDrawerHandle() {
      this.showAddDrawer = !this.showAddDrawer;
    },
    showOrHideUpdateDrawerHandle() {
      this.showUpdateDrawer = !this.showUpdateDrawer;
    },
    showOrHideCopyDrawerHandle() {
      this.showCopyDrawer = !this.showCopyDrawer;
    },
    refresh() {
      this.getTableData(!this.init);
      this.init = true;
      this.checked = false;
      this.changeCheckboxHandle("all");
    },
    onCancelDrawer() {
      this.show = !this.show;
      this.$emit("showOrHideDrawerHandle");
    },
  },
  mounted() {},
};
</script>

<style lang="less" scoped>
@import "../../../style/common/elementDrawerVip.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/vip/vip.less";
@import "../../../style/vip/vipPagination.less";
</style>

<style lang="less" scoped>
.vip-bill-rules {
  padding-left: 20px;
  .warning {
    font-size: 28px;
    color: red;
    margin-bottom: 20px;
  }

  .search {
    display: grid;
    grid-template-columns: 300px 400px;
    grid-gap: 10px;

    .row {
      span {
        font-size: 13px;
      }
    }
  }
}
</style>
