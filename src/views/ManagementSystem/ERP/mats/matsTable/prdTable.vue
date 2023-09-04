<template>
  <div class="prd-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdateErpLibHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateErpLibHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <icon-button @click.native="showImportDrawer = true" text="批量导入" img="btn_batch_import.png" colors="#f5f5f5"></icon-button>
      <characters-button @click.native="editTwoCategoryHandle" colors="#383943" wz='批量修改物料分类'></characters-button>

    </div>
    <div class="table-content">
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
            <div class="th">物料名称</div>
            <div class="th">拼音简写</div>
            <div class="th">物料单位</div>
            <div class="th">有无空瓶回收</div>
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
            <div class="td">{{item.np}}</div>
            <div class="td">{{item.un}}</div>
            <div class="td">{{item.r}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 新增或编辑 -->
        <addOrUpdatePrd v-model="showDrawer" :prdId="currentInfo.id" :type="type" :menuList="menuList" @getTableData="getTableData" />

        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :nexDrawerInfo="nexDrawerInfo" :effectType="effectType" @getTableData="getTableData" @setEffectOrNotEffect="setEffectOrNotEffect" />

        <!-- 批量导入 -->
        <drawerImportAll v-model="showImportDrawer" @getTableData="getTableData" @getMenuList="$emit('getMenuList')" />

        <!-- 批量设置二级分类 -->
        <setTwoSecondCategory
          :showDrawer="setSecondCategory.showDrawer"
          @showOrHideSetSecondCategoryHandle="showOrHideSetSecondCategoryHandle"
          @submitSecondCategoryHandle="submitSecondCategoryHandle"
        />
      </div>
    </div>
  </div>
</template>
 
<script>
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import addOrUpdatePrd from './prdTableCom/drawerAddOrUpdatePrd.vue'
import drawerNextDrawer from './prdTableCom/drawerNextDrawer.vue'
import setTwoSecondCategory from './prdTableCom/setTwoCategory.vue'
import drawerImportAll from './prdTableCom/drawerImportAll.vue'
export default {
  data() {
    return {
      tableData: [],
      checkAll: false,
      type: 1, // 1:新增  2：修改
      effectType: 1, // 1无效  2有效  3删除
      currentInfo: {}, // 当前修改的数据
      showDrawer: false,
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      showImportDrawer: false, // 批量导入
      nexDrawerInfo: {
        ns: [],
        cs: []
      },
      /*批量设置二级分类 */
      setSecondCategory: {
        showDrawer: false
      }
    };
  },
  methods: {
    async getTableData() {
      const params = {
        id: this.$route.query.menuId * 1 || 0
      }
      try {
        const res = await this.$api.ERP.mat.requestmatlist(params);
        if (res.code == 1) {
          this.tableData = (res.data || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checkAll = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    // 新增或修改
    addOrUpdateErpLibHandle(type) {
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
        const api = type == 1 ? 'requestmatdisable' : (type == 2 ? 'requestmatenable' : 'requestmatdel')
        const res = await this.$api.ERP.mat[api](params)
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

    // 修改分类
    editTwoCategoryHandle(){
      const checkList = this.tableData.filter(item => item.checked)
      if(checkList.length == 0) return this.$message.warning('请选择需要修改分类的商品')
      this.showOrHideSetSecondCategoryHandle();
    },
    // 显示或隐藏修改商品分类
    showOrHideSetSecondCategoryHandle(){
      this.setSecondCategory.showDrawer = !this.setSecondCategory.showDrawer;
    },
    // 提交修改商品分类
    async submitSecondCategoryHandle(secondId){
      const params = {
        mat_ids: this.tableData.filter(item => item.checked).map(item => item.id * 1), //    []int64   待操作商品Id
        two_cate_id: secondId * 1, // int64    目标二级分类Id
      }

      try {
        const res = await this.$api.ERP.mat.reqSetSecondCategory(params);
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
    }
  },
  components: {
    EllipsisTooltip,
    CharactersButton,
    IconButton,
    addOrUpdatePrd,
    drawerNextDrawer,
    drawerImportAll,
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
  }
  .table-content {
    .table {
      max-height: calc(100vh - 160px);
      overflow: auto;
      .th,.td{
        &:nth-child(1),
        &:nth-child(8){
          width: 30%;
        }
        &:nth-child(2){
          width: 70%;
        }
        &:nth-child(6),
        &:nth-child(7){
          width: 60%;
        }
      }
    }
  }
}
</style>