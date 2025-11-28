<template>
  <div class="prd-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdatePrdHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateGroupHandle(1)" text="新增套餐" img="btn_new_package.png" colors="#f5f5f5"></icon-button>
      <icon-button @click.native="updatePrdOrGroupHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <icon-button @click.native="showImportDrawer = true" text="批量导入" img="btn_batch_import.png" colors="#f5f5f5"></icon-button>
      <characters-button @click.native="showOrHideAreaLibraryHandle" colors="#f5f5f5" wz="批量设置区域出品库"></characters-button>
      <characters-button @click.native="editTwoCategoryHandle" colors="#383943" wz='批量修改商品分类'></characters-button>
      <characters-button @click.native="setMp" colors="#383943" wz='批量设置商品不可见'></characters-button>
      <characters-button @click.native="$message.info('上下拖动商品可调整顺序')" colors="#383943" wz='调整顺序'></characters-button>
      <characters-button @click.native="updatePrdOrGroupHandle(3)" colors="#383943" wz='类似创建'></characters-button>
    </div>
    <div class="table-content" ref="tableRef">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">商品名称</div>
            <div class="th">时段限制</div>
            <div class="th">时段</div>
            <div class="th">英文名称</div>
            <div class="th">商品类型</div>
            <div class="th">业务类型</div>
            <div class="th">商品单价</div>
            <div class="th">erp商品名称</div>
            <div class="th">是否限制仅用于优惠</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">状态</div>
            <div class="th">小程序可见</div>
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
              <span class="tips" v-if="item.pt.includes('小费') || item.pt.includes('特饮')">{{item.pt.includes('小费') ? 'X' : (item.pt.includes('特饮') ? 'T' : '')}}</span>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.enable_time_limit}}</div>
            <div class="td">{{item.time_range}}</div>
            <div class="td">{{item.ne}}</div>
            <div class="td">{{item.pt}}</div>
            <div class="td">{{item.bt}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.mn}}</div>
            <div class="td">{{item.ut}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.mp}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 新增或编辑单品 -->
        <addOrUpdatePrd v-model="showDrawer" :currentInfo="currentInfo" :type="type" @getTableData="getTableData" />

        <!-- 新增或编辑套餐 -->
        <addOrUpdateGroupPrd v-model="showGroupDrawer" :currentInfo="currentInfo" :type="groupPrdType" @getTableData="getTableData" />

        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :nexDrawerInfo="nexDrawerInfo" :effectType="effectType" :selectedIds="selectedIds" @getTableData="getTableData" @setEffectOrNotEffect="setEffectOrNotEffect" />

        <!-- 批量导入 -->
        <drawerImportAll v-model="showImportDrawer" @getTableData="getTableData" @getMenuList="$emit('getMenuList')" />
    
        <!-- 批量设置区域出品库 -->
        <setAreaLibrary
          :showDrawer="setAreaLibrary.showDrawer"
          @showOrHideAreaLibraryHandle="showOrHideAreaLibraryHandle"
        />
        <!-- 批量设置二级分类 -->
        <setTwoSecondCategory
          :showDrawer="setSecondCategory.showDrawer"
          @showOrHideSetSecondCategoryHandle="showOrHideSetSecondCategoryHandle"
          @submitSecondCategoryHandle="submitSecondCategoryHandle"
        />
      </div>
    </div>
    <el-dialog
        title="批量设置商品不可见"
        :visible.sync="dialogVisible"
        width="30%"
        center>
        <div>
          <el-checkbox v-model="limitPc">PC端</el-checkbox>
          <el-checkbox v-model="limitPad">PAD端</el-checkbox>
          <el-checkbox v-model="limitXcxEmp">小程序-员工端</el-checkbox>
          <el-checkbox v-model="limitXcxCust">小程序-客人端</el-checkbox>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogVisible = false">取 消</el-button>
          <el-button type="primary" @click="setMpOK">确 定</el-button>
        </span>
    </el-dialog>

  </div>
</template>
 
<script>
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import addOrUpdatePrd from './prdTableCom/drawerAddOrUpdatePrd.vue'
import addOrUpdateGroupPrd from './prdTableCom/drawerAddOrUpdateGroupPrd.vue'
import drawerNextDrawer from './prdTableCom/drawerNextDrawer.vue'
import setAreaLibrary from "./prdTableCom/setAreaLibrary.vue";
import setTwoSecondCategory from './prdTableCom/setTwoCategory.vue'
import drawerImportAll from './prdTableCom/drawerImportAll.vue'
import eventVue from "@/utils/eventVue";
export default {
  data() {
    return {
      safeModeEnabled: false,
      dialogVisible: false,
      showInMp: '1',
      oldItem: {}, // 拖拽初始信息
      newItem: {}, // 拖拽过程中信息
      tableData: [],
      checkAll: false,
      type: 1, // 1:新增单品  2：修改单品
      groupPrdType: 1, // 1:新增  2：修改  3：类似创建
      effectType: 1, // 1无效  2有效  3删除
      currentInfo: {}, // 当前修改的数据
      showDrawer: false,  // 新增或修改单品
      showGroupDrawer: false, // 新增或修改套餐
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      showImportDrawer: false, // 批量导入
      nexDrawerInfo: {
        ns: [],
        cs: []
      },      

      /* 批量设置区域出品库 */
      setAreaLibrary: {
        showDrawer: false
      },

      /*批量设置二级分类 */
      setSecondCategory: {
        showDrawer: false
      },
      limitPc: false,
      limitPad: false,
      limitXcxEmp: false,
      limitXcxCust: false,
      selectedIds: [], // 新增 selectedIds
    };
  },
  methods: {
    async getTableData(isScrollToBottom = false) {
      const params = {
        id: this.$route.query.menuId * 1 || 0
      }
      try {
        const res = await this.$api.BMS.Prd.requestprdlist(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || [])
            // 当 safeModeEnabled 为 true 时,过滤掉非主营商品和单价大于2000的商品
            .filter(item => {
              if(this.safeModeEnabled) {
                if(item.bt === '非主营商品') return false
                if(item.p * 1 > 2000) return false
              }
              return true
            })
            .map(item => ({
              ...item,
              enable_time_limit: res.data.enable_time_limit,
              time_range: res.data.time_range,
              checked: false
            }));
          this.checkAll = false;
          
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

    // 新增或修改单品
    addOrUpdatePrdHandle(type) {
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

    // 新增/修改套餐
    addOrUpdateGroupHandle(){
      this.groupPrdType = 1
      this.showGroupDrawer = true
    },

    updatePrdOrGroupHandle(groupPrdType){
      // groupPrdType  2 编辑  3 类似创建
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length == 1) {
        this.groupPrdType = groupPrdType
        this.currentInfo = checkedList[0]
        if(groupPrdType == 2) {
          // 编辑
          if([2,12,22,32].includes(this.currentInfo.pi)) {
            // 编辑套餐
            this.showGroupDrawer = true
          } else {
            // 编辑单品
            this.addOrUpdatePrdHandle(2)
          }
        } else {
          // 类似创建
          if ([2,12,22,32].includes(this.currentInfo.pi)) {
            // 类似创建套餐
            this.showGroupDrawer = true
          } else {
            this.$message.warning('类似创建只可创建套餐')
          }
        }
        // if(this.currentInfo.)
      } else {
        return this.$message.warning('请选择一条数据进行操作')
      }
    },

    // 设为有效或无效或删除
    async setEffectOrNotEffect(type){
      this.effectType = type
      // type : 1无效  2有效 3删除
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length <= 0) return this.$message.warning('请选择一个进行操作')
      const params = {
        ids: checkedList.map(item => item.id * 1)
      }
      try {
        const api = type == 1 ? 'requestprddisable' : (type == 2 ? 'requestprdenable' : 'requestprddel')
        const res = await this.$api.BMS.Prd[api](params)
        if(res.code == 1) {
          this.getTableData()
          this.$message.success('操作成功')
        } else if(res.code == 2) {
          this.selectedIds = params.ids // 保存选中的 ids
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
        console.log('设置有效无效删除失败', error);
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
          const res = await this.$api.BMS.Prd.requestprdmove_dsp(params)
          if(res.code == 1) {
            this.$message.success("更改位置成功")
            let newList = [...this.tableData]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            // 更新this.List，触发transition-group的动画效果
            this.tableData = [...newList];
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          
        }
      }
    },


    // 批量设置区域出品库
    showOrHideAreaLibraryHandle() {
      this.setAreaLibrary.showDrawer = !this.setAreaLibrary.showDrawer;
    },

    // 修改分类
    editTwoCategoryHandle(){
      const checkList = this.tableData.filter(item => item.checked)
      if(checkList.length == 0) return this.$message.warning('请选择需要修改分类的商品')
      this.showOrHideSetSecondCategoryHandle();
    },
    setMp(){
      const checkList = this.tableData.filter(item => item.checked)
      if(checkList.length == 0) return this.$message.warning('请选择需要设置小程序可见的商品')
      this.dialogVisible = true
    },
    async setMpOK(){
      let checkList = this.tableData.filter(item => item.checked)
      const params = {
        ids: checkList.map(item => item.id * 1),
        limit_pc: this.limitPc ? 1 : 2,
        limit_pad: this.limitPad ? 1 : 2,
        limit_xcx_emp: this.limitXcxEmp ? 1 : 2,
        limit_xcx_cust: this.limitXcxCust ? 1 : 2
      }
      try {
        const res = await this.$api.BMS.Prd['reqSetMp'](params)
        if(res.code == 1) {
          this.getTableData()
          this.$message.success('操作成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('设置不可见失败', error);
      } finally {
        // 重置选项
        this.limitPc = false;
        this.limitPad = false;
        this.limitXcxEmp = false;
        this.limitXcxCust = false;
        this.dialogVisible = false;
      }
    },

    // 显示或隐藏修改商品分类
    showOrHideSetSecondCategoryHandle(){
      this.setSecondCategory.showDrawer = !this.setSecondCategory.showDrawer;
    },
    // 提交修改商品分类
    async submitSecondCategoryHandle(secondId){
      const params = {
        prd_ids: this.tableData.filter(item => item.checked).map(item => item.id * 1), //    []int64   待操作商品Id
        two_cate_id: secondId * 1, // int64    目标二级分类Id
      }

      try {
        const res = await this.$api.BMS.Prd.reqSetSecondCategory(params);
        if (res.code == 1){
          this.$message.success('操作成功');
          this.showOrHideSetSecondCategoryHandle();
          this.getTableData()
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('批量设置二级分类失败', error)
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
  props: {
    menuList:{
      default: () => ({})
    }
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    },
  },
  mounted() {
    let safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || []
    this.safeModeEnabled = safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1)
    eventVue.$on("safeModeChanged", (e) => {
      console.log('safeModeChanged', e)
      this.safeModeEnabled = e[0][0] * 1 === 1 && e[0][1] * 1 === 1
      console.log('safeModeEnabled coming here', this.safeModeEnabled)
      this.getTableData()
    });
    this.authName =
      this.$store.state.userInfo && this.$store.state.userInfo.name;
    this.showOrHideModelVisible();

    this.getTabShowCount(this.getAllData);
  },
  beforeDestroy() {
    eventVue.$off("safeModeChanged")
  },
  components: {
    EllipsisTooltip,
    CharactersButton,
    IconButton,
    addOrUpdatePrd,
    addOrUpdateGroupPrd,
    drawerNextDrawer,
    drawerImportAll,
    setAreaLibrary,
    setTwoSecondCategory
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
.prd-table {
  padding: 20px;
  .top {
    background-color: #eee;
    flex-wrap: wrap;
  }
  .table-content {
    max-height: calc(100vh - 210px);
    overflow: auto;
    .table {
      min-width: 1800px;
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

          &.gray .td span.tips {
            background-color: #ccc;
          }
        }
      }
      .th,.td {
        &:nth-child(1){
          position: sticky;
          left: 0;
          span.tips {
            position: absolute;
            right: 0%;
            top: 50%;
            transform: translateY(-50%);
            width: 16px;
            height: 16px;
            line-height: 16px;
            text-align: center;
            font-size: 12px;
            font-weight: 600;
            color: #fff;
            background-color: rgb(0, 180, 132);
            border-radius: 4px;
          }
        }
        &:nth-child(2){
          position: sticky;
          left: 90px;
        }
      }
    }
  }
}
</style>