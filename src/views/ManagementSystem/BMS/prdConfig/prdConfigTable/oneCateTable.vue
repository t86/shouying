<template>
  <div class="one-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdateOneCateHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateOneCateHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <icon-button @click.native="showImportDrawer = true" text="批量导入" img="btn_batch_import.png" colors="#f5f5f5"></icon-button>
      <characters-button @click.native="$message.info('上下拖动分类可调整顺序')" colors="#383943" wz='调整顺序'></characters-button>
    </div>
    <div class="table-content table1">
      <div class="table" ref="tableRef">
        <div class="thead">
          <div class="tr" 
            layout="row"
            layout-align="space-between center"
            >
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">一级分类名称</div>
            <div class="th">首选出品库</div>
            <div class="th">微信小程序是否可见</div>
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
            :draggable="true"
            @dragstart="dragstart(item)" 
            @dragenter="dragenter(item)" 
            @dragend="dragend(item)"
            title="拖动可调整顺序"
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
            <div class="td">{{item.fmk}}</div>
            <div class="td">{{item.sm}}</div>
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
        <drawerAddOrUpdateOneCate @getMenuList="$emit('getMenuList')" v-model="showDrawer" :currentInfo="currentInfo" :type="type" @getTableData="getTableData" />
        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :effectType="effectType" :nexDrawerInfo="nexDrawerInfo"  @getTableData="getTableData" />
      </div>
    </div>
    <h3 class="m-t-3 m-b-3">商品列表</h3>
    <div class="table-content table2">
      <div class="table">
        <div class="thead">
          <div class="tr" 
            layout="row"
            layout-align="space-between center"
            >
            <div class="th">序号</div>
            <div class="th">商品名称</div>
            <div class="th">商品单价</div>
            <div class="th">商品类型</div>
            <div class="th">业务类型</div>
            <div class="th">拼音</div>
            <div class="th">英文名</div>
            <div class="th">状态</div>
            <div class="th">erp商品名称</div>
            <div class="th">一级分类名称</div>
            <div class="th">二级分类名称</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked,'gray': item.s == '无效'}"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in prdInfo.prdTableData"
            :key="item.id"
          >
            <div class="td">{{index + 1}}</div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.pt}}</div>
            <div class="td">{{item.bt}}</div>
            <div class="td">{{item.np}}</div>
            <div class="td">{{item.ne}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.en}}</div>
            <div class="td">{{item.on}}</div>
            <div class="td">{{item.tn}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 新增或编辑一级分类 -->
        <drawerAddOrUpdateOneCate @getMenuList="$emit('getMenuList')" v-model="showDrawer" :currentInfo="currentInfo" :type="type" @getTableData="getTableData" />
        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :effectType="effectType" :nexDrawerInfo="nexDrawerInfo"  @getTableData="getTableData" @setEffectOrNotEffect="setEffectOrNotEffect" />
        
        <!-- 批量导入 -->
        <drawerImportAll v-model="showImportDrawer" @getTableData="getTableData" @getMenuList="$emit('getMenuList')" />
      </div>
    </div>
    <div class="fr m-t-4">
      <el-pagination
        background
        layout="prev, pager, next"
        @current-change="changePageHandle"
        :page-size="prdInfo.pageSize"
        :total="prdInfo.allSize">
      </el-pagination>
    </div>
  </div>
</template>
 
<script>
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import drawerAddOrUpdateOneCate from './oneCateTableCom/drawerAddOrUpdateOneCate.vue'
import drawerNextDrawer from './oneCateTableCom/drawerNextDrawer.vue'
import drawerImportAll from './prdTableCom/drawerImportAll.vue'
export default {
  data() {
    return {
      oldItem: {}, // 拖拽初始信息
      newItem: {}, // 拖拽过程中信息
      tableData: [],
      checkAll: false,
      type: 1, // 1:新增  2：修改
      effectType: 1, // 1无效  2有效 3删除
      currentInfo: {}, // 当前修改的数据
      showDrawer: false,
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      nexDrawerInfo: {
        ns: [],
        cs: []
      },
      
      prdInfo: {
        prdTableData: [],
        page: 1,
        pageSize: 20,
        allSize: 0
      },

      showImportDrawer: false, // 批量导入
    };
  },
  methods: {
    async getTableData(isScrollToBottom = false) {
      try {
        const res = await this.$api.BMS.ocate.requestocatelist();
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

    async getPrdTableData() {
      const params = {
        page_num: this.prdInfo.page * 1, //   int  指定第几页
        page_size: this.prdInfo.pageSize, //  int  每页行数
      }
      try {
        const res = await this.$api.BMS.ocate.reqGetPrdList(params);
        if (res.code == 1) {
          this.prdInfo.prdTableData = res.data.records || []
          this.prdInfo.page = res.data.page_num || 1;
          this.prdInfo.allSize = res.data.row_cnt;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    changePageHandle(page) {
      this.prdInfo.page = page
      this.getPrdTableData()
    },

    // 新增或修改erp仓库 
    addOrUpdateOneCateHandle(type) {
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
        const api = type == 1 ? 'requestocatedisable' : (type == 2 ? 'requestocateenable' : 'requestocatedel')
        const res = await this.$api.BMS.ocate[api](params)
        if(res.code == 1) {
          this.getTableData()
          this.$emit('getMenuList')
          this.$message.success('操作成功')
        } else if(res.code == 2) {
          this.showNextDrawer = true
          this.nexDrawerInfo.ns = res.data.ns || []
          this.nexDrawerInfo.cs = (res.data.cs || []).map(item => ({
            ...item,
            jg: '---'
          }))
        }  else if (res.code == 500) {
          this.$message.warning('服务器异常，请稍后在试')
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
      this.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.newItem = item;
    },
    // 做最终操作
    async dragend(item) {
      if (this.oldItem != this.newItem) {
        let oldIndex = this.tableData.indexOf(this.oldItem);
        let newIndex = this.tableData.indexOf(this.newItem);
        let down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2
        } else if (oldIndex < newIndex) {
          down_up = 1
        }

        const params = {
          id: this.oldItem.id,
          dest_id: this.newItem.id,
          down_up: down_up
        }
        try {
          const res = await this.$api.BMS.ocate.requestocatemove_dsp(params)
          if(res.code == 1) {
            this.$message.success("更改位置成功")
            let newList = [...this.tableData]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            // 更新this.List，触发transition-group的动画效果
            this.tableData = [...newList];
            this.$emit('getMenuList')
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          
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
    this.getPrdTableData()
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
    drawerAddOrUpdateOneCate,
    drawerNextDrawer,
    drawerImportAll
  },
  watch: {
    '$route': {
      handler() {
        this.getTableData()
        this.getPrdTableData()
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
  .top {
    background-color: #eee;
  }
  .table-content {
    &.table1 {
      .table {
        height: calc(50vh - 260px);
        overflow: auto;
        .th,.td{
          &:nth-child(1),
          &:nth-child(7){
            width: 30%;
          }
          &:nth-child(2){
            width: 60%;
          }
        }
      }
    }

    &.table2 {
      height: calc(50vh - 20px);
      overflow: auto;
      .table {
        min-width: 2200px;
        .thead {
          .th {
            background-color: #f5f5f5;
          }
        }
        .tbody {
          .tr{
            &:nth-child(2n) {
              .td {
                background-color: #f5f5f5;
              }
            }
            &:nth-child(2n + 1) {
              .td {
                background-color: #f9f9f9;
              }
            }
          }
        }
        .th,.td {
          &:nth-child(1),
          &:nth-child(3),
          &:nth-child(4),
          &:nth-child(5),
          &:nth-child(8){
            width: 25%;
          }
          
          &:nth-child(2),
          &:nth-child(9){
            width: 80%;
          }

          &:nth-child(1){
            position: sticky;
            left: 0;
          }
          &:nth-child(2){
            position: sticky;
            left: 98px;
          }
        }
      }
    }
  }
}
</style>