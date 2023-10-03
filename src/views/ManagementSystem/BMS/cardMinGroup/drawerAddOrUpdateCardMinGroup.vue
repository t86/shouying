<template>
  <div>
    <!-- 添加或修改卡台抵消组 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">抵消组名称：</span>
          </div>
          <div class="value">
            <el-input v-model="name" placeholder="请输入低消组名称" @input="validator" />
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">最低消费金额(元)：</span>
          </div>
          <div class="value">
            <el-input v-model="money" placeholder="请输入最低消费金额(元)" />
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span class="fs14">卡台列表：</span>
          </div>
          <div class="value">
            <el-button type="primary" size="small" @click.native="showDrawer = true">选择</el-button>
          </div>
        </div>
        <div class="clip table m-t-3" v-if="tableData.length > 0">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">区域名称</div>
              <div class="th">区域状态</div>
              <div class="th">卡台名称</div>
              <div class="th">卡台状态</div>
            </div>
          </div>
          <div class="tbody">
            <div class="tr" layout="row" layout-align="start center" v-for="item in tableData" :key="item.id">
              <div class="td" :style="{'height': Math.max(30, item.is.length * 31) + 'px','line-height': Math.max(30, item.is.length * 31) + 'px'}">&nbsp;{{item.n}}</div>
              <div class="td" :style="{'height': Math.max(30, item.is.length * 31) + 'px','line-height': Math.max(30, item.is.length * 31) + 'px'}">&nbsp;{{item.s == 1? '有效':'无效'}}</div>
              <div class="td">
                <div class="td-td" v-for="items in item.is" :key="items.id">{{items.n}}</div>
              </div>
              <div class="td">
                <div class="td-td" v-for="items in item.is" :key="items.id">{{item.s == 1? '有效':'无效'}}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <drawerChooseCard v-model="showDrawer" :cardAllList="cardAllList" @changeCardAllList="changeCardAllList" />

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import drawerChooseCard from './drawerChooseCard.vue'
export default {
  data() {
    return {
      name: "",
      money: '',
      tableData: [],
      cardAllList: [],
      showDrawer: false,  // 是否显示选择卡台drawer
    };
  },
  methods: {
    // form表单检测
    validator() {
      if (this.name == "") {
        this.$message.warning("请输入低消组名称");
      } else if (this.$overall.character(this.name) > 20) {
        this.$message.warning("输入文字长度超过10");
      }
    },

    // 获取所有区域卡台
    async getCardListAll(){
      try {
        const res = await this.$api.BMS.seat_grp.requestseat_grpseat_map()
        if(res.code == 1) {
          this.cardAllList = (res.data.regions || []).map(item => ({
            ...item,
            is: (item.is || []).map(item => ({
              ...item,
              checked: this.tableData.some(items => items.is.find(ite => ite.id == item.id))
            }))
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取区域卡台列表失败', error);
      }
    },

    // 获取修改前的数据
    async getData(){
      const params = {
        id: this.currentInfo.id
      }
      try {
        const res = await this.$api.BMS.seat_grp.requestseat_grpget(params)
        if(res.code == 1) {
          this.name = res.data.name
          this.money = res.data.min_csm_amt
          this.tableData = (res.data.regions || []).map(item => ({
            ...item,
            is: item.is || []
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取修改前数据失败', error);
      }
    },

    // 更新选择卡台的数据
    changeCardAllList(cardList) {
      const tableData = []
      this.cardAllList = [...cardList]
      cardList.forEach(el => {
        const obj = {}
        obj.id = el.id
        obj.n = el.n
        obj.s = el.s
        obj.is = el.is.filter(item => item.checked)
        if(obj.is.length > 0) tableData.push(obj)
      })
      this.tableData = [...tableData]
    },

    async onSubmit() {
      const params = {
        name: this.name,
        min_csm_amt: this.money * 1,
        seat_ids: this.tableData.map(item => item.is).flat().map(item => item.id),
        ...this.type == 2 && {id: this.currentInfo.id}
      };
      try {
        const api = this.type == 1 ? "requestseat_grpnew" : "requestseat_grpsave";
        const res = await this.$api.BMS.seat_grp[api](params);
        if (res.code == 1) {
          this.onCancelDrawer();
          this.$message.success('操作成功')
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("提交失败", error);
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
      default: 1 // 1 新增  2 编辑
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增卡台低消组" : "编辑卡台低消组";
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
  components: {
    drawerChooseCard
  },
  watch: {
    value: {
      async handler(newVal) {
        if (newVal) {
          if(this.type == 2) {
            await this.getData()
          } else {
            this.name = ''
            this.money = ''
            this.tableData = []
          }
          this.getCardListAll()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/erp/form.less";
@import "../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
@color: #666;

.coll {
  .label {
    width: 160px;
    text-align: right;
  }
}
.table.clip {
  border-top: 1px solid @color;
  border-left: 1px solid @color;
  .thead {
    font-weight: 600;
    background-color: #f5f5f5;
  }
  .tr {
    min-height: 30px;
    line-height: 30px;
  }
  .th,.td {
    width: 50%;
    min-height: 30px;
    border-bottom: 1px solid @color;
    border-right: 1px solid @color;
  }
  .th {
    padding: 0 5px;
    box-sizing: border-box;
  }
  .td-td {
    width: 100%;
    min-height: 30px;
    line-height: 30px;
    border-bottom: 1px solid @color;
    padding: 0 5px;
    box-sizing: border-box;
    &:nth-last-child(1) {
      border: none;
    }
  }
}
</style>