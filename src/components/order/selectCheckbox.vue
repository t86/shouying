<template>
  <div>
    <div class="bg" v-if="showOption" @click="showOption = false"></div>
    <div class="select-checkbox">
      <div class="model-val" @click="showOption = true" :class="{ active: showOption }">
        <span class="model-val-item" v-for="(item, index) in valueList" :key="index">
          <span>{{ item.name }}</span>
          <i class="el-icon-circle-close" @click.stop="valueItemClickHandle(item)"></i>
        </span>
        <p v-if="valueList.length==0">{{requestVal=="" ? '请选择要求' : requestVal}}</p>
      </div>
      <ul class="model-option" v-if="showOption">
        <li
          class="flex-between"
          v-for="(item, index) in optionsList"
          :key="index"
          @click.stop="clickOption(item)"
        >
          <span>{{ item.name }}</span>
          <i v-if="item.checked" class="el-icon-check"></i>
        </li>
      </ul>
    </div>

    <!-- 自定义要求 -->
    <el-dialog title="请输入自定义要求" :visible="showInput" append-to-body>
      <input class="requested" maxlength="30" placeholder="请输入30字以内的要求" v-model="requestVal" />
      <div slot="footer" class="dialog-footer">
        <el-button @click="showInput = false">取 消</el-button>
        <el-button type="primary" @click="submitQuest">确 定</el-button>
      </div>
    </el-dialog>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      showInput: false, // 是否显示自定义要求输入框
      requestVal: "", // 自定义要求
      showOption: false, // 是否显示option
      valueList: [], // 选中option的展示值
      optionsList: [] // option列表
    };
  },
  methods: {
    clickOption(optionInfo) {
      if (optionInfo.id === 999999) {
        // 点击的是自定义要求
        this.showOption = false;
        this.showInput = true;
        this.requestVal = "";
        return;
      }
      // 是否为修改自定义要求，是的话清空自定义要求
      if (this.valueList.length == 1 && this.valueList[0].id == 0)
        this.valueList = [];

      optionInfo.checked = !optionInfo.checked;
      optionInfo.checked
        ? this.valueList.push(optionInfo)
        : this.valueItemClickHandle(optionInfo, true);
    },
    valueItemClickHandle(item, isOption = false) {
      if (item.id === 0) {
        // 文本框删除自定义要求
        this.valueList = [];
        this.requestVal = "";
        return;
      }
      if (!isOption) item.checked = !item.checked;
      const index = this.valueList.findIndex(el => el.id === item.id);
      this.valueList.splice(index, 1);
    },
    submitQuest() {
      if (this.requestVal != "") {
        // 判断为否输入了自定义要求，没输入则沿用之前选中的要求
        this.valueList = [
          {
            name: this.requestVal,
            id: 0,
            checked: false
          }
        ];
        this.optionsList.forEach(el => {
          el.checked = false;
        });
      }

      this.showInput = false;
    }
  },
  mounted() {
    this.optionsList = this.optionList;
    this.valueList = this.valueOriginList || this.valueList;
  },
  props: ["optionList", "valueOriginList"],
  watch: {
    optionList(newVal) {
      this.optionsList = newVal;
    },
    valueList(newVal) {
      this.$emit("updateRequest", newVal);
    },
    valueOriginList(newVal) {
      this.valueList = newVal;
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../style/common/elementDialog.less";
</style>

<style scoped>
ul,
li {
  margin: 0;
  padding: 0;
  list-style: none;
}

.bg {
  position: fixed;
  width: 100vw;
  height: 100vh;
  left: 0;
  top: 0;
  z-index: 9;
}

/* 自定义输入框 */
input.requested {
  width: 100%;
  height: 40px;
  border: 1px solid #ccc;
  border-radius: 8px;
  padding: 0 10px;
  box-sizing: border-box;
  outline: none;
  background: rgba(0, 0, 0, 0.2);
  color: #fff;
}

input:focus {
  border-color: #09f;
}

.model-val {
  position: relative;
  z-index: 9;
  width: 100%;
  min-height: 42px;
  border: 1px solid #ccc;
  border-radius: 8px;
  text-align: left;
  padding: 0 10px;
  box-sizing: border-box;
  cursor: pointer;
}

.model-val.active {
  border-color: #09f;
}

.model-val i {
  cursor: pointer;
}

.model-val-item {
  margin-right: 4px;
  padding: 4px;
  height: 30px;
  border: 1px solid #ccc;
  white-space: nowrap;
  border-radius: 4px;
}

.flex-between {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.model-option {
  position: absolute;
  top: 100%;
  left: 0;
  z-index: 9;
  width: 100%;
  max-height: 300px;
  border: 1px solid #ccc;
  overflow-y: auto;
  background: #000;
}

.model-option li {
  padding: 2px 14px;
  box-sizing: border-box;
  cursor: pointer;
}

.model-option li:hover {
  background-color: rgba(90, 90, 90, 0.5);
}
</style>