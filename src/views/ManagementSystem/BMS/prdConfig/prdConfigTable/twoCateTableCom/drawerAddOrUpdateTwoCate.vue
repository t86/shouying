<template>
  <div>
    <!-- 新增或修改二级级分类 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="coll m-b-2" layout="row" layout-align="start center">
          <div class="label">
            <span>一级分类名称:</span>
          </div>
          <div class="value">{{oneCateInfo.n}}</div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>二级分类名称:</span>
          </div>
          <div class="value">
            <el-input
              v-model="twoCateName"
              size="small"
              @change="limitingRule"
              placeholder="请输入二级分类名称"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>分类可选要求类型:</span>
          </div>
          <div class="value">
            <el-checkbox
              v-for="(item) in requireList" 
              :key="item.id"
              v-model="item.checked">
              {{item.n}}
            </el-checkbox>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      oneCateInfo: {},
      twoCateName: "",
      requireList: []
    };
  },
  methods: {
    // 获取编辑前信息
    async getDetail(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.BMS.tcate.requesttcateget(params)
        if(res.code == 1) {
          this.twoCateName = res.data.two_cate_info.name
          this.oneCateInfo = {
            n: res.data.two_cate_info.one_cate_name,
            id: res.data.two_cate_info.one_cate_id
          }
          this.requireList = (res.data.rqm_types || []).map(item => ({
            ...item,
            checked: res.data.two_cate_info.rqm_types && res.data.two_cate_info.rqm_types.includes(item.id)
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },
    // 获取要求类型列表
    async getRequireList(){
      try {
        const res = await this.$api.BMS.require.requestRqmTypelist()
        if(res.code == 1) {
          this.requireList = (res.data || []).map(item => ({
            ...item,
            checked: false
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    limitingRule(){
      if (this.twoCateName == '') {
        this.$message.warning('请输入二级分类名称')
      } else if (this.$overall.character(this.twoCateName) > 16) {
        this.$message.warning('输入文字长度超过8')
      }
    },

    async onSubmit() {
      if (this.twoCateName.length <= 0)
        return this.$message.warning("请输入二级分类名称");
      const params = {
        name: this.twoCateName || '',
        rqm_types: this.requireList.filter(item => item.checked).map(item => item.id * 1),
        ...this.type == 1 && {one_cate_id: this.oneCateInfo.id},
        ...this.type == 2 && {id : this.currentInfo.id}
      };
      try {
        const api = this.type == 1 ? 'requesttcatenew' : 'requesttcatesave'
        const res = await this.$api.BMS.tcate[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$emit('getMenuList')
          this.$message.success('操作成功')
        } else if (res.code == 6) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$emit('getMenuList')
          this.$message.warning("创建成功，状态无效，" + res.msg)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
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
      default: 1
    },
    menuList: {
      default: () => ([])
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增二级分类" : "编辑二级分类";
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
          if (this.type == 1) {
            this.twoCateName = "";
            const oneCateInfo = this.menuList.find(item => item.id == this.$route.query.menuId)
            this.oneCateInfo = oneCateInfo || {}
            this.getRequireList()
          } else {
            this.getDetail()
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
</style>
<style lang="less" scoped>
.coll {
  margin-bottom: 20px;
  .label {
    width: 150px;
  }
}
</style>