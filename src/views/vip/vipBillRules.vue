<template>
  <!-- 会员卡号生成规则 -->
  <div class="vip vip-bill-rules">
    <h3 class="title">会员卡结账规则</h3>
    <div class="warning">
      说明：未在表单中配置规则的商品, 如使用会员卡渠道,只能使用储值金额结账
    </div>

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
      <div class="row m-t-4" layout="row" layout-align="start center">
        <button class="btn primary" @click="create">新增</button>
        <button class="btn primary m-l-4" @click="batchDelete">批量删除</button>
        <button class="btn primary large m-l-4" @click="batchChange">
          批量更改扣款规则
        </button>
      </div>
    </div>

    <div class="contain">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
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
            :key="index"
            layout="row"
            layout-align="space-between center"
            @click.right.prevent.stop="rightClickHandle($event, item)"
          >
            <div class="td">{{ index + 1 }}</div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.bp }}</div>
            <div class="td">{{ item.cp }}</div>
            <div class="td">{{ item.s }}</div>
            <div class="td">{{ item.b }}</div>
            <div class="td" layout="row" layout-align="start center">
              <span>{{ item.cn }}</span>
              <img
                v-if="item.h == 1"
                :src="require('@/assets/vip-imgs/vip-manager-icon.png')"
              />
            </div>
            <div class="td">{{ item.ct }}</div>
            <div class="td">{{ item.cl }}</div>
            <div class="td">{{ item.m }}</div>
            <div class="td fs16-bold">{{ item.ba }}</div>
            <div class="td"></div>
            <div class="td">{{ item.lc }}</div>
            <div class="td">{{ item.r }}</div>
            <div class="td">{{ item.e }}</div>
            <div class="td">
              <span @click="preVipDetail(item)">查看详情</span>
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
  </div>
</template>

<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      cateOptions: [],
      cateVal: [],
      keyword: "",
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },
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
      };
      try {
        const res = await api_vip.reqGetVipBillRuleList(params);
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
          this.pageInfo.total = res.data.row_cnt || 0;
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("会员管理表格数据获取失败", error);
      }
    },
    resetHandle() {
      this.productVal = [];
      this.productOption = "";
      this.keyword = [];
      this.getTableData(true);
    },
    create() {},
    batchDelete() {},
    batchChange() {},
    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },
  },
  mounted() {
    this.getTableData(true);
  },
};
</script>

<style lang="less" scoped>
@import "../../style/common/elementDrawerVip.less";
@import "../../style/vip/vipBtn.less";
@import "../../style/vip/vip.less";
@import "../../style/vip/vipPagination.less";
</style>

<style lang="less" scoped>
.vip-bill-rules {
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
