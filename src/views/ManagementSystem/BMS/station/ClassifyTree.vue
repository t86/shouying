<template>
  <div class="tree_box">
    <div class="all">
      <el-checkbox
        :indeterminate="isIndeterminateAll"
        v-model="checkAll"
        @change="handleCheckAllChange"
      >以下全部勾选&ensp;</el-checkbox>
      <!-- 一级菜单 -->
      <div class="classify_one" v-for="(item) in tree" :key="item.id">
        <el-checkbox
          :indeterminate="item.st==3"
          v-model="item.c"
          @change="classifyOneChange($event, item)"
        >
          <span style="display:inline-block;width:105px;">{{item.n}}</span>
        </el-checkbox>
        <input
          v-if="showPrice"
          class="price-input first-category"
          :class="{'black': !(item.c||item.st==3)}"
          v-model="item.price"
          :disabled="!(item.c||item.st==3)"
          placeholder="请输入价格"
        />
        <span
          v-if="showPrice"
          class="reset-btn"
          :class="{'disabled':!(item.c||item.st==3)}"
          @click.stop="resetAllTwoCategory(item)"
        >重置</span>
        <!-- 二级菜单 -->
        <div class="classify_two" v-for="(v) in item.subs" :key="v.id">
          <el-checkbox
            :indeterminate="v.st==3"
            v-model="v.c"
            @change="classifyTwoChange($event, item, v)"
          >
            <span style="display:inline-block;width:80px;">{{v.n}}</span>
          </el-checkbox>
          <input
            v-if="showPrice"
            class="price-input"
            :class="{'black': !v.c,'button': v.ma==-1&&canUpdateVal}"
            v-model="v.price"
            :disabled="!v.c"
            placeholder="请输入价格"
            @input="Change(tree)"
            @click.stop="changeDifferent(v)"
          />
          <span v-if="showPrice" :class="{'black': !v.c}">元以下</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "ClassifyTree",
  props: {
    treeData: Array,
    resetStatus: Boolean,
    showPrice: {
      default: false
    }
  },
  data() {
    return {
      tree: [],
      isIndeterminateAll: false,
      checkAll: false,

      // 是否修改所选岗位不同价格金额
      canUpdateVal: false
    };
  },
  components: {},
  methods: {
    //一级分类
    classifyOneChange(val, item) {
      this.tree.map(v => {
        if (v.id == item.id) {
          v.c = val;
          v.st = val ? 1 : 2;
          v.subs &&
            v.subs.map(m => {
              m.c = val;
              m.st = val ? 1 : 2;
            });
        }
      });
    },
    //二级分类
    classifyTwoChange(val, item, x) {
      x.price = "";
      this.tree.map(v => {
        if (v.id == item.id) {
          v.subs &&
            v.subs.map(m => {
              if (m.id == x.id) {
                m.c = val;
                m.st = val ? 1 : 2;
              }
            });
        }
      });
    },
    //全选操作
    handleCheckAllChange(val) {
      this.tree.map(v => {
        v.c = val;
        v.st = val ? 1 : 2;
        v.subs &&
          v.subs.map(m => {
            m.c = val;
            m.st = val ? 1 : 2;
          });
      });
    },
    //父子关系绑定
    Change(after) {
      after.forEach(el => {
        el.subs &&
          el.subs.forEach(ele => {
            ele.st = ele.st == 1 || ele.st == 2 || ele.st == 3 ? ele.st : 2;
            ele.c = ele.st == 1;
          });
        el.c = el.subs && el.subs.length > 0 ? el.subs.every(item => item.c) : false;
        el.st = el.c
          ? 1 : el.subs
          ? el.subs.some(item => item.st == 1 || item.st == 3) ? 3 : 2
          : 2;
      });
      this.checkAll = after.every(item => item.c);
      this.isIndeterminateAll = this.checkAll
        ? false
        : after.some(item => item.c);

      this.tree = after;
      this.$emit("onChange", this.tree);
    },

    // 重置二级菜单价格
    resetAllTwoCategory(firstCategoryInfo) {
      firstCategoryInfo.subs.forEach(el => {
        if (el.c) el.price = firstCategoryInfo.price;
        else el.price = "";
      });
      this.$forceUpdate();
    },

    // 修改所选岗位金额不同发生冲突的情况
    changeDifferent(itemInfo) {
      if (!this.canUpdateVal&&itemInfo.ma==-1) {
        this.$confirm("所选多个岗位对应金额不同，确认修改吗", "友情提示", {
          distinguishCancelAndClose: true,
          confirmButtonText: "确定",
          cancelButtonText: "取消"
        })
          .then(() => {
            this.canUpdateVal = true;
          })
          .catch(e => "");
      }
    }
  },
  created() {
    this.tree = this.treeData;
    this.Change(this.treeData);
  },
  computed: {
    treeArr() {
      return JSON.parse(JSON.stringify(this.tree));
    }
  },
  watch: {
    treeData(news, olds) {
      if (news.length == 0) {
        this.isIndeterminateAll = false;
        this.checkAll = false;
      }
      news.forEach(el => {
        el.price = "";
        el.subs.forEach(ele => {
          ele.price = ele.ma == -1 ? "原值" : ele.ma;
          ele.c = ele.c || ele.st == 3
        });
      });
      this.tree = news;
      this.Change(news);
    },
    resetStatus(news, olds) {
      if (news != olds) {
        this.isIndeterminateAll = false;
        this.checkAll = false;
      }
    },
    // 根据商品名称改变拼音 限制价格
    treeArr: {
      deep: true,
      handler: function(after, before) {
        this.Change(this.tree);
      }
    }
  }
};
</script>

<style lang="less">
@import '../../../../style/common/elementConfirm.less';
</style>

<style>
.tree_box {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  max-height: 700px;
  min-width: 400px;
  overflow: scroll;
}

.classify_one {
  margin-left: 25px;
}

.classify_two {
  margin-left: 25px;
}

.tree_box .el-checkbox {
  margin-top: 2px;
  margin-bottom: 2px;
}

.price-input {
  width: 80px;
  padding: 2px 4px;
  box-sizing: border-box;
  margin-left: 10px;
  border-radius: 2px;
  background-color: transparent;
  border: 1px solid rgb(140, 140, 140);
  font-size: 12px;
}


.price-input::placeholder {
  color: rgb(140, 140, 140);
  font-size: 12px;
}

.black {
  border-color: #999;
  color: #999;
}

.black::placeholder {
  color: #999;
}

.button {
  cursor: pointer;
}

.reset-btn {
  background-color: #2170ff;
  border-color: #2170ff;
  color: #fff;
  padding: 4px 6px;
  border-radius: 4px;
  cursor: pointer;
}

.reset-btn.disabled {
  color: #999;
  background-color: #ddd;
}
</style>