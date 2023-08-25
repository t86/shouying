<template>
  <div>
    <!-- 选择卡台 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      append-to-body
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <h3 class="m-b-2">全量配置：</h3>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">不限制设备：</div>
          <div class="value">
            <el-checkbox v-model="checkAll" @change="changeCheckBoxHandle('all')"></el-checkbox>
          </div>
        </div>
        <h3 class="m-t-6 m-b-2">单独配置设备:</h3>
        <div v-for="item in cardList" :key="item.id" v-show="item.ss.length > 0">
          <h3 class="m-t-3 m-b-3">
            {{item.n}}
            <el-checkbox
              :indeterminate="item.isIndeterminate"
              v-model="item.checked"
              :disabled="item.disabled"
              @change="changeCheckBoxHandle('item', item)"
            ></el-checkbox>
          </h3>
          <div class="card-area" layout="row" layout-align="start center">
            <div
              class="card-item cursor"
              :class="{border: items.checked}"
              v-for="items in item.ss"
              :key="items.id"
            >
              <div class="card-content" @click.stop="chooseCard(item, items)">
                <h3>{{items.n}}</h3>
                <img
                  v-if="items.checked"
                  :class="{border: items.checked}"
                  :src="require('@/assets/img/分配卡台选中角.png')"
                  alt
                />
              </div>
            </div>
          </div>
        </div>
      </div>
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
      checkAll: false,
      cardList: []
    };
  },
  methods: {
    async getCardListInfo() {
      const params = {
        id: this.currentInfo.id * 1 //   int64    终端Id
      };
      try {
        const res = await this.$api.BMS.terminal.reqGetTerminalAreaAndSeat(
          params
        );
        if (res.code == 1) {
          this.checkAll = res.data.is_all == 1;
          this.cardList = (res.data.regions || []).map(item => ({
            ...item,
            checked: item.st == 1,
            disabled: this.checkAll,
            isIndeterminate:
              item.st != 1 && (item.ss || []).some(items => items.st == 1),
            ss: (item.ss || []).map(items => ({
              ...items,
              checked: item.st == 1 ? true : items.st == 1,
              disabled: this.checkAll
            }))
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    changeCheckBoxHandle(type, itemInfo) {
      switch (type) {
        case "all":
          this.cardList = this.cardList.map(item => ({
            ...item,
            checked: false,
            isIndeterminate: false,
            disabled: this.checkAll,
            ss: item.ss.map(items => ({
              ...items,
              checked: false,
              disabled: this.checkAll
            }))
          }))
          break;
        case "item":
          itemInfo.ss = itemInfo.ss.map(item => ({
            ...item,
            checked: itemInfo.checked
          }));
          break;
      }
    },

    chooseCard(areaInfo, cardInfo) {
      if(cardInfo.disabled) return this.$message.warning('不限制设备条件下不可选择单独配置设备，请先取消不限制设备后，再操作')
      cardInfo.checked = !cardInfo.checked;
      areaInfo.checkAll = areaInfo.ss.every(item => item.checked);
      areaInfo.isIndeterminate =
        !areaInfo.checkAll && areaInfo.ss.some(item => item.checked);
    },

    async onSubmit() {
      const areaListId = []
      const cardListId = []
      if(!this.checkAll) {
        this.cardList.forEach(el => {
          if(el.checked){
            areaListId.push(el.id)
          } else {
            el.ss.forEach(ele => {
              if(ele.checked) {
                cardListId.push(ele.id)
              }
            })
          }
        });
      }
      const params = {
        id: this.currentInfo.id * 1, //    int64    终端Id
        is_all: this.checkAll ? 1 : 2, //     int    全选标记 1 全选 2 未全选
        sel_region_ids: areaListId, // []int64    选中区域Id列表
        sel_seat_ids: cardListId // []int64   选中卡台列表
      };
      try {
        const res = await this.$api.BMS.terminal.reqSaveTerminalAreaAndSeat(
          params
        );
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.$emit('getTableData')
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
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
    currentInfo: {
      default: {}
    }
  },
  computed: {
    title() {
      return "选择区域/卡台";
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
          this.checkAll = false
          this.getCardListInfo();
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
</style>

<style lang="less" scoped>
.session {
  padding: 20px;
  .card-area {
    flex-wrap: wrap;
    .card-item {
      position: relative;
      text-align: center;
      width: 100px;
      height: 50px;
      margin: 10px;
      padding: 4px;
      border-radius: 2px;
      border: 2px solid transparent;
      &.border {
        border-color: rgb(33, 112, 225);
      }
      .card-content {
        width: 100%;
        box-sizing: border-box;
        height: 100%;
        line-height: 40px;
        background-color: #eee;
        border: 1px solid #999;

        img {
          width: 20px;
          position: absolute;
          top: 0;
          left: 0;
        }
      }
    }
  }
}
</style>