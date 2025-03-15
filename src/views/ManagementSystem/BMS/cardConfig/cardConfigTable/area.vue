<template>
  <div class="one-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdateHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <characters-button @click.native="scrollBottom" colors="#383943" wz='调整顺序'></characters-button>
    </div>
    <div class="table-content">
      <div class="table" ref="tableRef">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">区域名称</div>
            <div class="th">卡台数量</div>
            <div class="th">必点商品</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">状态</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked,'gray': item.s == '无效'}"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
            draggable="true"
            @dragstart="dragstart(item)"
            @dragenter="dragenter(item)"
            @dragend="dragend(item)"
          >
            <div class="td">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
              </div>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.sc}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 新增或编辑一级分类 -->
        <drawerAddOrUpdateArea @getMenuList="$emit('getMenuList')" v-model="showDrawer" :currentInfo="currentInfo" :type="type" @getTableData="getTableData" />
        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :effectType="effectType" :nexDrawerInfo="nexDrawerInfo"  @getTableData="getTableData" @setEffectOrNotEffect="setEffectOrNotEffect" />
      </div>
    </div>
  </div>
</template>
 
<script>
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import drawerAddOrUpdateArea from './areaTableCom/drawerAddOrUpdateArea.vue'
import drawerNextDrawer from './areaTableCom/drawerNextDrawer.vue'
export default {
  data() {
    return {
      tableData: [],
      checkAll: false,
      type: 1, // 1:新增  2：修改
      effectType: 1, // 1无效  2有效 3删除
      dragInfo: {}, // 拖拽信息
      currentInfo: {}, // 当前修改的数据
      showDrawer: false,
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      nexDrawerInfo: {
        ns: [],
        cs: []
      }
    };
  },
  methods: {
    async getTableData(isScrollToBottom = false) {
      try {
        const res = await this.$api.BMS.region.requestregionlist();
        if (res.code == 1) {
          this.tableData = (res.data || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checkAll = false;
          this.$emit('getMenuList')
          if(isScrollToBottom) {
            this.$nextTick(() => {
              this.scrollBottom()
            })
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    // 新增或修改
    addOrUpdateHandle(type) {
      const checkedList = this.tableData.filter(item => item.checked)
      if(type == 2) {
        if(checkedList.length == 1) {
          this.currentInfo = checkedList[0]
        } else {
          return this.$message.warning('请选择一条数据进行操作')
        }
      }
      this.showDrawer = true
      this.type = type
    },

    // 设为有效或无效或删除
    async setEffectOrNotEffect(type){
      // type : 1无效  2有效 3删除
      this.effectType = type
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length <= 0) return this.$message.warning('请选择一个进行操作')
      const params = {
        ids: checkedList.map(item => item.id * 1)
      }
      try {
        const api = type == 1 ? 'requestregiondisable' : (type == 2 ? 'requestregionenable' : 'requestregiondel')
        const res = await this.$api.BMS.region[api](params)
        if(res.code == 1) {
          this.getTableData()
          this.$message.success('操作成功')
        } else if(res.code == 2) {
          this.showNextDrawer = true
          this.nexDrawerInfo.ns = res.data.ns || []
          this.nexDrawerInfo.cs = (res.data.cs || []).map(item => ({
            ...item,
            jg: '---'
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('设置有效无效失败', error);
      }
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

    // 记录初始信息
    dragstart(item) {
      this.dragInfo.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.dragInfo.newItem = item;
    },
    // 做最终操作
    async dragend(item) {
      if (this.dragInfo.oldItem != this.dragInfo.newItem) {
        let oldIndex = this.tableData.findIndex(items => items.id == this.dragInfo.oldItem.id);
        let newIndex = this.tableData.findIndex(items => items.id == this.dragInfo.newItem.id);
        const downUp = oldIndex > newIndex ? 2 : 1;

        const params = {
          id: this.dragInfo.oldItem.id,
          dest_id: this.dragInfo.newItem.id,
          down_up: downUp
        }

        try {
          const res = await this.$api.BMS.region.requestregionmove_dsp(params)
          if(res.code == 1) {
            this.$message.success('更改位置成功')
            const newList = [...this.tableData]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            //             // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.dragInfo.oldItem);
            //             // 更新this.List，触发transition-group的动画效果
            this.tableData = [...newList];
            this.$emit('getMenuList')
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('排序提交失败', error);
        }
      }
    },

    scrollBottom(){
      this.$nextTick(() => {
        const dom = this.$refs.tableRef
        dom && dom.scrollTo(0, 10000)
      })
    }
  },
  created() {
    this.getTableData();
  },
  mounted() {},
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  components: {
    CharactersButton,
    IconButton,
    drawerAddOrUpdateArea,
    drawerNextDrawer
  },
  watch: {
    '$route': {
      handler() {
        this.getTableData()
      }
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.one-table {
  padding: 20px;
  height: 100%;
  position: relative;
  display: flex;
  flex-direction: column;

  .top {
    background-color: #eee;
    padding: 10px;
    position: sticky;
    top: 0;
    z-index: 10;
  }

  .table-content {
    flex: 1;
    overflow: auto;
    
    .table {
      .th,.td{
        &:nth-child(4){
          width: 100%
        }
      }
    }
  }
}
</style>