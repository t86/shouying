<template>
  <div>
    <el-drawer
      title="选择数量"
      append-to-body
      :visible.sync="show"
      direction="rtl"
      size="90%"
      :before-close="onCancelDrawer"
    >
      <div class="content">
        <div class="session m-b-10">
          <div class="info">
            <div class="item" layout="row" layout-align="start center">
              <div class="label">所选商品：</div>
              <div class="value">{{ currentWineInfo.n }}</div>
            </div>
            <div class="item border" layout="row" layout-align="start center">
              <div class="label" style="color: red; font-size: large">
                整瓶数量：
              </div>
              <div class="value" layout="row" layout-align="start center">
                <img
                  :src="
                    chooseCount > 0
                      ? require('@/assets/order-img/sub.png')
                      : require('@/assets/order-img/sub-disabled.png')
                  "
                  @click="chooseCount--"
                />
                <input
                  type="number"
                  @click="focus = '-1'"
                  :class="{ focus: focus == -1 }"
                  :min="0"
                  v-model="chooseCount"
                />
                <img
                  :src="
                    (type == 1 && currentChooseCount < maxCount) || type == 2
                      ? require('@/assets/order-img/order_add.png')
                      : require('@/assets/order-img/add-disabled.png')
                  "
                  @click="chooseCount++"
                />
              </div>
            </div>
          </div>

          <div
            class="info-detail m-t-6"
            layout="row"
            layout-align="space-between start"
          >
            <div class="left">
              <div class="title m-b-3" style="color: red; font-size: large">
                散瓶数量：
              </div>
              <div class="table-content">
                <div class="table">
                  <div class="thead">
                    <div
                      class="tr"
                      layout="row"
                      layout-align="space-between center"
                    >
                      <div class="th">
                        <img
                          @click="addRowHandle"
                          :src="require('@/assets/order-img/add-count.png')"
                        />
                      </div>
                      <div class="th">散瓶规格</div>
                      <div class="th">每瓶克数</div>
                      <div class="th">数量</div>
                    </div>
                  </div>
                  <div class="tbody">
                    <div
                      class="tr"
                      layout="row"
                      layout-align="space-between center"
                      v-for="(item, index) in tableData"
                      :key="item.id"
                    >
                      <div class="td">
                        <img
                          @click="deleteHandle(item.id)"
                          :src="require('@/assets/order-img/delete.png')"
                        />
                      </div>
                      <div class="td">
                        <el-select
                          v-model="item.selectVal"
                          size="mini"
                          style="width: 80%"
                          placeholder="请选择"
                        >
                          <el-option
                            v-for="items in selectOption"
                            :key="items.value"
                            :label="items.name"
                            :value="items.name"
                          >
                          </el-option>
                        </el-select>
                      </div>
                      <div class="td" layout="row" layout-align="start center">
                        <input
                          @click="
                            focus = index;
                            itemText = 'weight';
                          "
                          :class="{
                            focus: focus == index && itemText == 'weight',
                          }"
                          type="number"
                          :min="1"
                          v-model="item.allWeight"
                        />克
                      </div>
                      <div class="td" layout="row" layout-align="start center">
                        <img
                          :src="
                            item.count > 1
                              ? require('@/assets/order-img/sub.png')
                              : require('@/assets/order-img/sub-disabled.png')
                          "
                          @click="changeItemCountHandle(item, 'sub')"
                        />
                        <input
                          type="number"
                          @click="
                            focus = index;
                            itemText = 'count';
                          "
                          :class="{
                            focus: focus == index && itemText == 'count',
                          }"
                          :min="1"
                          v-model="item.count"
                        />
                        <img
                          :src="
                            (type == 1 && currentChooseCount < maxCount) ||
                            type == 2
                              ? require('@/assets/order-img/order_add.png')
                              : require('@/assets/order-img/add-disabled.png')
                          "
                          @click="changeItemCountHandle(item, 'add')"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="right" @click.stop="">
              <keyBoard @changeNum="changeNumHandle" />
            </div>
          </div>
        </div>
        <!-- 提交按钮 -->
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
          <el-button :disabled="committing||!show" type="primary" @click.stop="onSubmit">确定</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_saveWine from "@/api/saveWine";
import keyBoard from "@/components/common/keyBoard.vue";
export default {
  data() {
    return {
      chooseCount: 0,
      focus: 0,
      itemText: "",
      tableData: [],
      committing: false,
      selectOption: [
        {
          id: 1,
          name: "0.1",
        },
        {
          id: 2,
          name: "0.2",
        },
        {
          id: 3,
          name: "0.3",
        },
        {
          id: 4,
          name: "0.4",
        },
        {
          id: 5,
          name: "0.5",
        },
        {
          id: 6,
          name: "0.6",
        },
        {
          id: 7,
          name: "0.7",
        },
        {
          id: 8,
          name: "0.8",
        },
        {
          id: 9,
          name: "0.9",
        },
      ],
    };
  },
  methods: {
    changeItemCountHandle(itemInfo, type) {
      if (type == "add") {
        if (this.type == 1) {
          const currentMaxCount =
            this.maxCount -
            this.chooseCount -
            this.tableData
              .filter((item) => item.id != itemInfo.id)
              .reduce((a, b) => a + b.count * 1, 0);
          if (itemInfo.count + 1 > currentMaxCount) {
            this.$message.warning(
              "整瓶数量和散瓶数量之和不得超过可存数量" + this.maxCount
            );
          }
          itemInfo.count = Math.min(itemInfo.count + 1, currentMaxCount * 1);
        } else {
          itemInfo.count = Math.max(itemInfo.count + 1, 1);
        }
      } else {
        itemInfo.count = Math.max(itemInfo.count - 1, 1);
      }
    },
    addRowHandle() {
      if (this.type == 1 && this.currentChooseCount >= this.maxCount) {
        return this.$message.warning(
          "整瓶数量和散瓶数量之和不得超过可存数量" + this.maxCount
        );
      }
      this.tableData = [
        ...this.tableData,
        {
          id: +new Date(),
          selectVal: "",
          allWeight: "",
          count: 1,
        },
      ];
    },
    deleteHandle(id) {
      const index = this.tableData.findIndex((item) => item.id == id);
      if (index > -1) {
        this.tableData.splice(index, 1);
        if (this.tableData.length < this.focus + 1) {
          this.focus = this.tableData.length - 1;
        }
      }
    },
    // 键盘
    changeNumHandle(value) {
      if (this.focus == -1) {
        // 整瓶
        switch (value) {
          case 10: // 清空
            this.chooseCount = "0";
            break;
          case 12: // 回退(
            this.chooseCount =
              this.chooseCount
                .toString()
                .slice(0, this.chooseCount.toString().length - 1) * 1;
            break;
          default:
            this.chooseCount =
              (this.chooseCount == 0 ? "" : this.chooseCount.toString()) +
              value * 1;
            break;
        }
      } else {
        let currentInfo = this.tableData[this.focus];
        if (!currentInfo) return;
        if (this.itemText == "weight") {
          switch (value) {
            case 10: // 清空
              currentInfo.allWeight = "";
              break;
            case 12: // 回退(
              currentInfo.allWeight =
                currentInfo.allWeight
                  .toString()
                  .slice(0, currentInfo.allWeight.toString().length - 1) * 1;
              break;
            default:
              currentInfo.allWeight =
                currentInfo.allWeight.toString() + value * 1;
              break;
          }
        } else if (this.itemText == "count") {
          switch (value) {
            case 10: // 清空
              currentInfo.count = "0";
              break;
            case 12: // 回退(
              currentInfo.count =
                currentInfo.count
                  .toString()
                  .slice(0, currentInfo.count.toString().length - 1) * 1;
              break;
            default:
              currentInfo.count =
                (currentInfo.count == 0 ? "" : currentInfo.count.toString()) +
                value * 1;
              break;
          }
          // 非授权存酒才计算
          if (this.type == 1) {
            const allCount = this.tableData.reduce(
              (a, b) => a + b.count * 1,
              0
            );
            if (allCount + this.chooseCount * 1 > this.maxCount * 1) {
              let anotherCount = 0;
              this.tableData.forEach((el, i) => {
                if (i != this.focus) {
                  anotherCount += el.count * 1;
                }
              });

              currentInfo.count =
                this.maxCount * 1 - anotherCount - this.chooseCount;
              this.$message.warning(
                "整瓶数量和散瓶数量之和不得超过可存数量" + this.maxCount
              );
            }
          }
        }
      }
      this.$forceUpdate();
    },

    async onSubmit() {
      if(this.committing || !this.show) {
        return
      }

      if (this.tableData.length > 0) {
        if (this.tableData.every((item) => item.selectVal * 1 == 0))
          return this.$message.warning("请选择商品规格");
        // if(this.tableData.every(item => item.allWeight * 1 == 0)) return this.$message.warning('请填写每瓶克数')
      }

      const resultList =
        this.chooseCount > 0
          ? [
              {
                id: +new Date(),
                selectVal: "1",
                allWeight: 0,
                count: this.chooseCount,
              },
              ...this.tableData,
            ]
          : [...this.tableData];

      if (this.type == 1) {
        // 流水存酒
        // 当前选择的总数量
        if (this.currentChooseCount > this.maxCount)
          return this.$message.warning(
            "整瓶数量和散瓶数量之和不得超过可存数量" + this.maxCount
          );

        const params = {
          csm_id: this.checkedOrderInfo.id * 1, //   int64   流水Id
          prd_id: this.currentWineInfo.id, //    []int64   商品Id列表
          unit_types: resultList.map((item) => item.selectVal.toString()), // []string   规格列表,对应上面的商品列表
          prd_cnts: resultList.map((item) => item.count * 1), //   []int   商品数量,对应上面的商品列表
          g_cnts: resultList.map((item) => item.allWeight * 1), //   []int   克数,,对应上面的商品列表
        };

        try {
          this.committing = true;
          const res = await api_saveWine.reqAddNotAuthWine(params);
          if (res.code == 1) {
            this.$message.success("添加成功");
            this.onCancelDrawer();
            this.$emit("getShoppingCartWineList");
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("添加存酒至购物车失败", error);
        }
      } else {
        this.$emit("addAuthWineHandle", resultList);
        this.onCancelDrawer();
      }
      this.committing = false;
    },

    onCancelDrawer(isClose) {
      this.show = false;
    },
  },
  props: {
    type: {
      default: 1, // 1:非授权酒水选择  2：授权酒水选择
    },
    value: false,
    maxCount: {
      default: 1,
    },
    currentWineInfo: {},
    checkedOrderInfo: {},
  },
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
    currentChooseCount() {
      return (
        this.tableData
          .map((item) => item.count * 1)
          .reduce((a, b) => a * 1 + b * 1, 0) + this.chooseCount * 1
      );
    },
  },
  components: {
    keyBoard,
  },
  watch: {
    value(newVal) {
      this.show = newVal;
      if (newVal) {
        this.chooseCount = 0;
        this.focus = 0;
        this.tableData = [];
      }
    },

    chooseCount(newVal) {
      if (this.type == 1) {
        const currentMaxCount =
          this.maxCount -
          this.tableData
            .map((item) => item.count * 1)
            .reduce((a, b) => a + b, 0);
        if (newVal < 0) {
          this.chooseCount = 0;
        } else if (newVal > currentMaxCount) {
          this.$message.warning(
            "整瓶数量和散瓶数量之和不得超过可存数量" + this.maxCount
          );
          this.chooseCount = currentMaxCount;
        }
      }
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawer.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtn.less";
@import "../../../../style/common/scrollBar.less";
@import "../../../../style/saveWine/table.less";
</style>

<style lang="less" scoped>
.content {
  padding: 0 20px;
  box-sizing: border-box;
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
  // 整瓶信息
  .info {
    .item {
      height: 50px;
      &.border {
        padding-bottom: 10px;
        border: none;
        border-bottom: 1px solid rgba(255, 255, 255, 0.15);
      }
      .value {
        font-size: 20px;
        margin-left: 10px;
        img {
          width: 24px;
          cursor: pointer;
        }
        input {
          width: 56px;
          margin: 0 6px;
          text-align: center;
          color: #fff;
          height: 28px;
          background: rgba(255, 255, 255, 0.08);
          border-radius: 24px;
          border: 1px solid rgba(255, 255, 255, 0.3);
          &.focus {
            background: rgba(0, 0, 0, 0.2);
            border: 1px solid #32b9ff;
            box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
          }
        }
      }
    }
  }

  // 散瓶信息
  .info-detail {
    .left {
      width: 60%;
      .table {
        .tbody {
          height: calc(100vh - 350px);
          overflow: auto;
        }
        .th,
        .td {
          width: 30%;
          img {
            width: 20px;
            cursor: pointer;
          }
          &:nth-child(1) {
            width: 10%;
          }

          input {
            width: 50px;
            height: 26px;
            border-radius: 13px;
            margin: 0 6px;
            font-size: 14px;
            text-align: center;
            box-sizing: border-box;
            &:focus {
              background: rgba(0, 0, 0, 0.2);
              border: 1px solid #32b9ff;
              box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
            }
          }
          .focus {
            background: rgba(0, 0, 0, 0.2);
            border: 1px solid #32b9ff;
            box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
          }
        }
      }
    }
    .right {
      width: 40%;
    }
  }
}
</style>

<style>
.el-scrollbar__view.el-select-dropdown__list {
  background-color: #2a3959 !important;
}
.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: #666 !important;
}
.el-select-dropdown__item {
  color: rgba(255, 255, 255, 0.8);
}
</style>
