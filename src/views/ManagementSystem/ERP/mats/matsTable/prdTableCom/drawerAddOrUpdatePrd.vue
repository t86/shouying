<template>
  <div>
    <!-- 新增或修改商品 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>物料名称:</span>
          </div>
          <div class="value">
            <el-input v-model="matName" size="mini" placeholder="请输入二级物料名称"></el-input>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span>拼音简写:</span>
          </div>
          <div class="value">{{py}}</div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span>物料空瓶回收:</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <el-radio v-model="canHS" label="1">有</el-radio>
            <el-radio v-model="canHS" label="2">无</el-radio>
          </div>
        </div>
        <div class="coll m-b-6" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>物料单位:</span>
          </div>
          <div class="value">
            <el-select size="mini" v-model="unit" placeholder="请选择物料单位">
              <el-option v-for="each in unitList" :key="each.id" :label="each.n" :value="each.id"></el-option>
            </el-select>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button v-if="search" type="danger" @click="deleteHandle">删除</el-button>
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
      matName: "",
      py: "",
      canHS: "2",
      unit: "",
      unitList: [],
      oneCateId: '',
      twoCateId: ''
    };
  },
  methods: {
    async getData(id = 0){
      const params = {
        id
      }
      try {
        const res = await this.$api.ERP.mat.requestmatget(params)
        if(res.code == 1) {
          this.unitList = (res.data.units || []).filter(item => item.s == 1)
          if(id != 0) {
            this.matName = res.data.mat.name
            this.py = res.data.mat.name_py
            this.canHS = res.data.mat.rtn_bottle.toString()
            this.unit = res.data.mat.unit_id
            this.oneCateId = res.data.mat.mat_one_cate_id
            this.twoCateId = res.data.mat.mat_two_cate_id
          } else {
            this.matName = ''
            this.py = ''
            this.canHS = '2'
            this.unit = ''
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取物料信息失败', error);
      }
    },

    async deleteHandle(){
      const params = {
        ids: [this.prdId * 1]
      }
      try {
        const res = await this.$api.ERP.mat.requestmatdel(params)
        if(res.code == 1) {
          this.$emit('initSearchValHandle')
          this.onCancelDrawer()
          this.$message.success('删除成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除失败', error);
      }
    },

    async onSubmit() {
      if (this.matName.length <= 0)
        return this.$message.warning("请输入物料名称");
      if (!this.unit)
        return this.$message.warning("请选择物料单位");
      const params = {
        name: this.matName,
        mat_one_cate_id: this.oneCateId * 1,
        mat_two_cate_id: this.twoCateId * 1,
        name_py: this.py,
        unit_id: this.unit * 1,
        rtn_bottle: this.canHS * 1, // int   空瓶回收 1 回收 2 不回收
        ...(this.type == 2 && { id: this.prdId })
      };
      try {
        const api = this.type == 1 ? "requestmatnew" : "requestmatchg";
        const res = await this.$api.ERP.mat[api](params);
        if (res.code == 1) {
          this.onCancelDrawer();
          this.$emit("getTableData");
          this.$emit("getMenuList");
          this.$message.success("操作成功");
        } else if(res.code == 6) {
          this.$message.warning("创建成功，状态无效，" + res.msg)
          this.onCancelDrawer();
          this.$emit("getTableData");
          this.$emit("getMenuList");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("新增失败", error);
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
    search: {
      default: false
    },
    menuList: {
      default: () => []
    },
    prdId: {
      default: 0
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增物料" : "编辑物料";
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
          this.getData(this.type == 1 ? 0 : this.prdId)
          if(this.type == 1) {
            this.twoCateId = this.$route.query.menuId
            this.menuList.forEach(el => {
              el.subs.forEach(ele => {
                if(ele.id == this.twoCateId) {
                  this.oneCateId = el.id
                }
              })
            })
          }
        }
      },
      immediate: true
    },
    matName: {
      async handler(newVal) {
        const params = {
          str: newVal
        };
        try {
          const res = await this.$api.UtilAuth.util.requestutilpy(params)
          if(res.code == 1) {
            this.py = res.data || ''
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('拼音获取失败', error);
        }
      }
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