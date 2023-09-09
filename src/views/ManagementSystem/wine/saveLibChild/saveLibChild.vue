<template>
    <!-- 存酒库 -->
    <div class="save-lib">
        <div class="top">
            <div class="item m-b-2" layout="row" layout-align="start center">
                <div class="label fs14">存酒日期：</div>
                <div class="value">
                    <el-date-picker style="width: 260px" v-model="dateVal" type="daterange" :clearable="false" size="small"
                        value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期"
                        end-placeholder="结束日期"></el-date-picker>
                </div>
            </div>
            <el-input v-model="keyword" style="width: 360px" class="m-r-2" size="small"
                placeholder="输入客人姓名/手机号码/商品/存酒流水号"></el-input>
            <el-button type="primary" size="small" @click="getTableData">查询</el-button>
            <el-button size="small" @click="resetHandle">重置</el-button>
        </div>

        <div class="table-content m-t-3">
            <div class="table">
                <div class="thead">
                    <div class="tr" layout="row" layout-align="space-between center">
                        <div class="th">序号</div>
                        <div class="th">酒水名称</div>
                        <div class="th">规格</div>
                        <div class="th">每瓶克数</div>
                        <div class="th">数量</div>
                        <div class="th">存酒时间</div>
                        <div class="th">过期时间</div>
                        <div class="th">存酒流水号</div>
                        <div class="th">订位人</div>
                        <div class="th">客人姓名</div>
                        <div class="th">客人手机号</div>
                        <div class="th">授权人</div>
                        <div class="th">备注姓名</div>
                        <div class="th">备注手机号</div>
                    </div>
                </div>
                <div class="tbody">
                    <div class="tr" layout="row" layout-align="space-between center" 
                    v-for="(item,index) in tableData"
                        :key="item.id">
                        <div class="td" layout="row" layout-align="start center">
                            <span>{{ index + 1 }}</span>
                        </div>
                        <div class="td">{{ item.n }}</div>
                        <div class="td">{{ item.u }}</div>
                        <div class="td">{{ item.g }}</div>
                        <div class="td">{{ item.c }}</div>
                        <div class="td">{{ item.it }}</div>
                        <div class="td">{{ item.e }}</div>
                        <div class="td">{{ item.i }}</div>
                        <div class="td">{{ item.se }}</div>
                        <div class="td">{{ item.cn }}</div>
                        <div class="td">{{ item.p }}</div>
                        <div class="td">{{ item.a }}</div>
                        <div class="td">{{ item.rn || "-" }}</div>
                        <div class="td">{{ item.rp || "-" }}</div>
                    </div>
                    <div class="no-data" v-if="tableData.length == 0">
                        <img src="@/assets/img/wu.png" alt />
                        <p>暂无数据</p>
                    </div>
                </div>
            </div>
        </div>

    </div>
</template>

<script>
import api_wine from "@/api/wine";

export default {
    data() {
        return {
            dateVal: ["", ""], // 存酒日期
            keyword: "",
            tableData: [],
        };
    },
    methods: {
        async getTableData() {
            const params = {
                start_bef_in_day: this.dateVal[0], //  string  开始日期,格式 yyyy-mm-dd
                end_bef_in_day: this.dateVal[1], // string  结束日期,格式 yyyy-mm-dd
                key: this.keyword || "", //  string     //Key 搜索关键字
            };

            try {
                const res = await api_wine.reqGetSaveLibChildList(params);
                if (res.code == 1) {
                    res.data.records = res.data.records || [];
                    //   const oneDay =
                    //     +new Date("2023/05/19 12:00") - +new Date("2023/05/18 12:00");
                    //   const sevenDayAgo = 7 * oneDay + +new Date();
                    //   res.data.records.forEach((el) => {
                    //     el.ss = (el.ss || []).map((item) => ({
                    //       ...item,
                    //       checked: false,
                    //       isShortTime: +new Date(item.e) - sevenDayAgo <= 0,
                    //     }));
                    //     el.show = true;
                    //     el.checkAll = false;
                    //     el.isIndeterminate = false;
                    //   });

                    this.tableData = res.data.records;
                    this.ids = [];
                } else {
                    this.$message.warning(res.msg);
                }
            } catch (error) {
                console.log("存酒库列表数据获取失败", error);
            }
        },

        resetHandle() {
            const oneHour =
                +new Date("2023/07/22 12:00:00") - +new Date("2023/07/22 11:00:00");
            const date = new Date(+new Date() - 8 * oneHour);
            const year = date.getFullYear();
            const month = (date.getMonth() + 1).toString().padStart(2, 0);
            const day = date.getDate().toString().padStart(2, 0);
            const now = year + "-" + month + "-" + day;
            this.dateVal = [now, now];
            this.keyword = "";
            this.getTableData();
        },
    },
    created() {
        this.resetHandle();
    },
    components: {},
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.save-lib {
    padding: 20px;

    .table-content {
        .table {
            .thead .th {
                font-size: 15px;
            }

            .tbody {
                height: calc(100vh - 200px);
                overflow-y: auto;
            }

            .th,.td{

                &:nth-child(1){
                    width: 30%;
                }
                &:nth-child(3),
                &:nth-child(4),
                &:nth-child(5){
                    width: 30%;
                }
                &:nth-child(6),
                &:nth-child(7)
                {
                    max-width: 88px;
                }
                &:nth-child(8)
                {
                    min-width: 150px;
                }
              
            }
        }
    }
}
</style>

<style>
/* 日期选择器 */
.el-date-picker__header-label {
    color: #1a1a21;
}

.el-date-table th,
.el-picker-panel__content {
    color: #1a1a21;
}

.el-range-editor--small .el-range-input {
    background-color: transparent;
}
</style>
