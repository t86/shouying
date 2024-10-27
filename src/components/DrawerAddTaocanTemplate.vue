<template>
  <el-drawer :title="type === 1 ? '新增套餐模板' : '编辑套餐模板'" :visible.sync="drawerVisible" :direction="direction"
    :before-close="handleClose" size="85%">
    <el-form :model="form" :rules="rules" ref="form" label-width="160px" class="w-5/6">
      <el-form-item label="模板名称" prop="name" required>
        <el-input v-model="form.name" placeholder="请输入模板名称"></el-input>
      </el-form-item>
      <el-form-item label="明细规则(N选M)" prop="count" required>
        <div class="flex">
          <span class="w-10">
            {{ selectedPrds.length }}选
          </span>
          <el-input type="number" v-model="form.count" placeholder="输入数量"></el-input>
        </div>
      </el-form-item>
      <el-form-item label="可选组单品" required>
        <el-button type="primary" size="medium" @click="clickNewPrd"> 新增</el-button>
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr flex items-center justify-between">
                <div class="th w-12">序号</div>
                <div class="th flex-grow">名称</div>
                <div class="th w-64">分类</div>
                <div class="th w-20">单价</div>
                <div class="th w-20">数量</div>
                <div class="th w-56">存货商品名</div>
                <div class="th w-20">类型</div>
                <div class="th w-24">营业类型</div>
                <div class="th w-16">状态</div>
                <div class="th w-16 text-center">操作</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr flex items-center justify-between" v-for="(item, index) in selectedPrds" :key="index">
                <div class="td w-12">{{ index + 1 }}</div>
                <div class="td flex-grow">{{ item.n }}</div>
                <div class="td w-64 truncate">{{ item.on }} > {{ item.tn }}</div>
                <div class="td w-20">{{ item.p }}</div>
                <div class="td w-20">
                  <el-input type="number" v-model="item.c" class="w-full"></el-input>
                </div>
                <div class="td w-56 truncate">{{ item.mn }}</div>
                <div class="td w-20">{{ item.pt }}</div>
                <div class="td w-24">{{ item.bt }}</div>
                <div class="td w-16">{{ item.s }}</div>
                <div class="td w-16 text-center">
                  <el-button type="text" @click="deletePrd(item)">删除</el-button>
                </div>
              </div>
              <div class="no-data" v-if="selectedPrds.length == 0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </el-form-item>
    </el-form>
    <div class="drawer-footer">
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" @click="submitForm">确定</el-button>
    </div>
    <drawerAddPrd v-model="showAddPrdDrawer" :checkedPrdList="selectedPrds" @selectedPrds="submitSelectedPrds" />

  </el-drawer>
</template>

<script>
import drawerAddPrd from "./drawerAddPrdNew"
export default {
  name: "DrawerAddTaocanTemplate",
  props: {
    type: {
      type: Number,
      required: true,
    },
    currentInfo: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      showAddPrdDrawer: false,
      drawerVisible: true,
      direction: "rtl",
      selectedPrds: [],
      form: {
        name: "",
        count: null,
      },
      rules: {
        name: [
          { required: true, message: "请输入模板名称", trigger: "blur" }
        ],
        count: [
          { required: true, message: "请输入数量", trigger: "blur" }
        ],

      },
    };
  },
  methods: {
    deletePrd(prd) {
      this.selectedPrds = this.selectedPrds.filter(item => item.id != prd.id)
    },
    submitSelectedPrds(prds) {
      console.log("submitSelectedPrds", prds);
      console.log("type:", this.type);
      // 创建一个映射来存储现有商品的数量
      const existingPrdMap = new Map(
        this.selectedPrds.map(item => [item.id, item.c])
      );

      // 更新 selectedPrds，保留现有商品的数量
      this.selectedPrds = prds.map(prd => ({
        ...prd,
        s: prd.s === 1 ? "有效" : (prd.s === 2 ? "无效" : prd.s),
        c: existingPrdMap.get(prd.id) || 1
      }));
    },
    clickNewPrd() {
      this.showAddPrdDrawer = true
    },
    handleClose() {
      this.$emit("closeDrawer");
    },
    submitForm() {
      this.$refs.form.validate((valid) => {
        if (valid) {
          // 这里添加提交表单的逻辑
          console.log("表单提交", this.form);
          
          const submitAction = async () => {
            let params = {
              name: this.form.name,
              sel_cnt: this.form.count * 1,
              prd_ids: this.selectedPrds.map(item => item.id),
              prd_cnts: this.selectedPrds.map(item => item.c * 1),
            }
            if (this.type === 2) {
              params.id = this.currentInfo.id
            }
            const res = this.type === 1 ? await this.$api.BMS.Prd.new_prd_set_tpl(params) : await this.$api.BMS.Prd.save_prd_set_tpl(params)
            res.code == 1 ? this.$message.success(this.type === 1 ? "创建成功" : "修改成功") : this.$message.warning(res.msg);
            this.handleClose();
          };

          if (this.type === 2) {
            this.$confirm('确认调整模板内容?调整后使用该模板的套餐也会一起调整!', '确认', {
              confirmButtonText: '确定',
              cancelButtonText: '取消',
              type: 'warning'
            }).then(submitAction).catch(() => {
              this.handleClose();
            });
          } else {
            submitAction();
          }
        } else {
          console.log("表单验证失败");
          return false;
        }
      });
    },
  },
  async created() {
    if (this.type === 2 && this.currentInfo) {
      let res = await this.$api.BMS.Prd.get_prd_set_tpl({ id: this.currentInfo.id })
      console.log(res)
      if (res.code === 1) {
        this.form.name = res.data.name
        this.form.count = res.data.sel_cnt
        let dts = res.data.dtls || []
        dts.forEach(item => {
          item.p = (item.p/100).toFixed(2)
        })
        this.selectedPrds = dts

      } else {
        this.$message.warning(res.msg);
      }
      // this.form = { ...this.currentInfo };
    }
  },
  components: {
    drawerAddPrd
  },
};
</script>

<style scoped lang="less">
@import "../style/erp/form.less";
// @import "../style/erp/table.less";
</style>

<style lang="less" scoped>
.drawer-footer {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 20px;
  text-align: center;
  background-color: #fff;
}
</style>
