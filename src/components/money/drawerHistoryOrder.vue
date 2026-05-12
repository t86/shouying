<template>
    <div class="order-detail">
        <el-drawer title="历史点单记录" :visible.sync="show" :before-close="onCancelDrawer" direction="rtl" size="98%">
            <div>
                <div class="top" layout="row" layout-align="space-between center">
                    <!-- <div class="row">
                        <span class="label">营业日:</span>
                        <el-select v-model="form.wkdayId" size="small" placeholder="请选择营业日" style="width: 200px"
                            @change="getTableData">
                            <el-option v-for="item in form.wkdayOptions" :key="item.id" :label="item.n"
                                :value="item.id">
                            </el-option>
                        </el-select>
                    </div> -->

                    <div class="top-left" layout="row" layout-align="start center">
                        <span class="label">营业日:</span>
                        <el-select v-model="form.wkdayId" size="small" placeholder="请选择营业日" style="width: 200px;margin-right: 10px;"
                            @change="getTableData">
                            <el-option v-for="item in form.wkdayOptions" :key="item.id" :label="item.n"
                                :value="item.id">
                            </el-option>
                        </el-select>
                        <input v-model="form.keyword" placeholder="订台人/点单人/商品名称" />
                        <el-button class="m-l-2" type="primary"
                            style="width: 70px; height: 30px; line-height: 30px; padding: 0"
                            @click="getTableData">查询</el-button>
                        <el-button type="info" style="width: 70px; height: 30px; line-height: 30px; padding: 0"
                            @click="resetHandle">重置</el-button>
                    </div>
                    <el-button type="primary" @click="exportExcel"
                        style="width: 90px; height: 30px; line-height: 30px; padding: 0">导出Excel</el-button>
                </div>

                <div class="table">
                    <div class="thead">
                        <div class="tr" layout="row" layout-align="start center">
                            <div class="th" style="width: 20px; max-width: 20px"></div>
                            <div class="th">营业日</div>
                            <div class="th">区域</div>
                            <div class="th">卡台流水</div>
                            <div class="th">订位人</div>
                            <div class="th">订位部门</div>
                            <div class="th">订位人岗位</div>
                            <div class="th">总订单金额</div>
                            <div class="th">总实收金额</div>
                            <div class="th">支付信息</div>
                        </div>
                    </div>
                    <div class="tbody">
                        <div v-for="(item, index) in tableData" :key="index">
                            <div class="tr" layout="row" layout-align="start center"
                                @click="toggleExpand(index)">
                                <div class="td" style="width: 20px; max-width: 20px;">
                                    <i :class="['el-icon-arrow-right', { 'expanded': item.expanded }]"></i>
                                </div>
                                <div class="td">{{ item.b }}</div>
                                <div class="td">{{ item.r }}</div>
                                <div class="td">{{ item.s }}</div>
                                <div class="td">{{ item.se }}</div>
                                <div class="td">{{ item.sd }}</div>
                                <div class="td">{{ item.ss }}</div>
                                <div class="td">{{ formatAmount(item.o) }}</div>
                                <div class="td">{{ formatAmount(item.p) }}</div>
                                <div class="td">{{ item.pi }}</div>
                            </div>
                            <!-- 展开的详细信息 -->
                            <div v-if="item.expanded" class="detail-table">
                                <div class="detail-header">
                                    <div class="tr" layout="row" layout-align="start center">
                                        <div class="th">点单时间</div>
                                        <div class="th">点单部门</div>
                                        <div class="th">点单人</div>
                                        <div class="th">点单人岗位</div>
                                        <div class="th">关联台</div>
                                        <div class="th">自助</div>
                                        <div class="th">商品一级分类</div>
                                        <div class="th">商品二级分类</div>
                                        <div class="th">商品名称</div>
                                        <div class="th">商品类型</div>
                                        <div class="th">业务类型</div>
                                        <div class="th">点单数量</div>
                                        <div class="th">点单金额</div>
                                        <div class="th">实收金额</div>
                                        <div class="th">支付信息</div>
                                    </div>
                                </div>
                                <div class="detail-body">
                                    <div class="tr" layout="row" layout-align="start center"
                                        v-for="(order, orderIndex) in item.os" 
                                        :key="orderIndex">
                                        <div class="td">{{ order.o }}</div>
                                        <div class="td">{{ order.d }}</div>
                                        <div class="td">{{ order.w }}</div>
                                        <div class="td">{{ order.ws }}</div>
                                        <div class="td">{{ order.ri }}</div>
                                        <div class="td">{{ order.co }}</div>
                                        <div class="td">{{ order.on }}</div>
                                        <div class="td">{{ order.tn }}</div>
                                        <div class="td">{{ order.p }}</div>
                                        <div class="td">{{ order.pt }}</div>
                                        <div class="td">{{ order.bt }}</div>
                                        <div class="td">{{ order.c }}</div>
                                        <div class="td">{{ formatAmount(order.oa) }}</div>
                                        <div class="td">{{ formatAmount(order.pa) }}</div>
                                        <div class="td">{{ order.pi }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align: center">
                            暂无数据
                        </p>
                    </div>
                </div>
            </div>
            <!-- 提交按钮 -->
            <div class="form-btn" layout="row" layout-align="center center">
                <el-button type="info" @click="onCancelDrawer">关闭</el-button>
            </div>
        </el-drawer>
    </div>
</template>

<script>
import api_money from "@/api/money";

export default {
    data() {
        return {
            show: false,
            form: {
                keyword: "",
                wkdayId: "",
                wkdayOptions: [],
            },
            tableData: [],
        };
    },
    methods: {
        // 获取营业日列表
        async getWkdayList() {
            try {
                const res = await api_money.get_csm_his_wkday_items();
                if (res.code === 1) {
                    this.form.wkdayOptions = res.data.records || [];
                    if (this.form.wkdayOptions.length > 0) {
                        this.form.wkdayId = this.form.wkdayOptions[0].id;
                        this.getTableData();
                    }
                } else {
                    this.$message.warning(res.msg);
                }
            } catch (error) {
                console.log("获取营业日列表失败", error);
            }
        },

        // 获取表格数据
        async getTableData() {
            if (!this.form.wkdayId) return;

            const params = {
                wkday_id: this.form.wkdayId,
                key: this.form.keyword
            };

            try {
                const res = await api_money.get_csm_his(params);
                if (res.code === 1) {
                    this.tableData = (res.data.records || []).map(item => ({
                        ...item,
                        expanded: false
                    }));
                } else {
                    this.$message.warning(res.msg);
                }
            } catch (error) {
                console.log("获取表格数据失败", error);
            }
        },

        // 导出excel
        async exportExcel() {
            if (!this.form.wkdayId) return;

            const params = {
                wkday_id: this.form.wkdayId,
                key: this.form.keyword
            };

            try {
                const res = await api_money.get_csm_hiexp_csm_hiss_wkday_items(params);
                if (!res.msg) {
                    const url = window.URL.createObjectURL(
                        new Blob([res], {
                            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        })
                    );
                    const a = document.createElement("a");
                    document.body.appendChild(a);
                    a.href = url;
                    a.setAttribute("download", decodeURIComponent(res.fileName));
                    a.click();
                    document.body.removeChild(a);
                    window.URL.revokeObjectURL(url);
                } else {
                    this.$message.warning(res.msg);
                }
            } catch (error) {
                console.log("导出excel失败", error);
            }
        },

        // 展开/收起详情
        toggleExpand(index) {
            this.$set(this.tableData[index], 'expanded', !this.tableData[index].expanded);
        },

        // 格式化金额
        formatAmount(amount) {
            return (amount / 100).toFixed(2);
        },

        onCancelDrawer() {
            this.$emit("showOrHideHistoryOrderDrawer");
        },

        resetHandle() {
            this.form.keyword = "";
            if (this.form.wkdayOptions.length > 0) {
                this.form.wkdayId = this.form.wkdayOptions[0].id;
            }
            this.getTableData();
        },
    },
    props: {
        showDrawer: {
            default: false,
        },
    },
    watch: {
        showDrawer(newVal) {
            this.show = newVal;
            if (newVal) {
                this.getWkdayList();
            }
        },
    },
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerHistoryOrder.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";

.el-icon-arrow-right {
    transition: transform 0.3s;
    cursor: pointer;

    &.expanded {
        transform: rotate(90deg);
    }
}
</style>

<style>
.el-select-dropdown {
    background-color: #2a3959 !important;
    border: 1px solid #4c5b7e !important;
}

/* .el-select-dropdown__item {
    color: #fff !important;
    
    &:hover, &.selected {
        background-color: #1e2b4c !important;
    }
} */
</style>
