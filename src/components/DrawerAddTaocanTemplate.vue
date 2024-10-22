<template>
    <el-drawer :title="type === 1 ? '新增套餐模板' : '编辑套餐模板'" :visible.sync="drawerVisible" :direction="direction"
        :before-close="handleClose" size="80%">
        <el-form :model="form" :rules="rules" ref="form" label-width="100px">
            <el-form-item label="模板名称" prop="name">
                <el-input v-model="form.name" placeholder="请输入模板名称"></el-input>
            </el-form-item>
            <!-- 这里可以添加更多的表单项 -->
        </el-form>
        <div class="drawer-footer">
            <el-button @click="handleClose">取消</el-button>
            <el-button type="primary" @click="submitForm">确定</el-button>
        </div>
    </el-drawer>
</template>

<script>
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
            drawerVisible: true,
            direction: "rtl",
            form: {
                name: "",
            },
            rules: {
                name: [
                    { required: true, message: "请输入模板名称", trigger: "blur" },
                    {
                        min: 2,
                        max: 20,
                        message: "长度在 2 到 20 个字符",
                        trigger: "blur",
                    },
                ],
            },
        };
    },
    methods: {
        handleClose() {
            this.$emit("closeDrawer");
        },
        submitForm() {
            this.$refs.form.validate((valid) => {
                if (valid) {
                    // 这里添加提交表单的逻辑
                    console.log("表单提交", this.form);
                    this.handleClose();
                } else {
                    console.log("表单验证失败");
                    return false;
                }
            });
        },
    },
    created() {
        if (this.type === 2 && this.currentInfo) {
            this.form = { ...this.currentInfo };
        }
    },
};
</script>

<style lang="less" scoped>
.drawer-footer {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    padding: 20px;
    text-align: center; // 将 text-align 从 right 改为 center
    background-color: #fff;
}
</style>
