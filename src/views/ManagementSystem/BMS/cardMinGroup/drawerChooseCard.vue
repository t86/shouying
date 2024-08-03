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
        <div v-for="item in cardList" :key="item.id" v-show="item.is.length > 0">
          <h3 class="m-t-3 m-b-3">{{item.n}}</h3>
          <div class="card-area" layout="row" layout-align="start center">
            <div class="card-item cursor" :class="{border: items.checked}" v-for="items in item.is" :key="items.id">
                <div class="card-content" :class="{taken: items.si > 0 && !items.my}" @click.stop="chooseCard(items)">
                  <h3>{{items.n}}</h3>
                  <img v-if="items.checked" :class="{border: items.checked}" :src="require('@/assets/img/assign_cards_to_select.png')" alt />
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
      cardList: []
    };
  },
  methods: {
    chooseCard(itemInfo){
      console.log(itemInfo, itemInfo.si > 0)
      if(itemInfo.si > 0 && !itemInfo.my) {
        return
      }
      this.cardList = this.cardList.map(item => ({
        ...item,
        is: item.is.map(items => ({
          ...items,
          checked: items.id == itemInfo.id ? !itemInfo.checked : items.checked
        }))
      }))
    },
    async onSubmit() {
      this.$emit('changeCardAllList', this.cardList)
      this.onCancelDrawer()
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
    cardAllList: {
      default: []
    }
  },
  computed: {
    title() {
      return "选择卡台";
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
          this.cardList = JSON.parse(JSON.stringify(this.cardAllList));
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
      .taken {
        background-color: gray;
        font-weight: 200;
      }
    }
  }
}


</style>