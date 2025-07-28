# FoloUp B2C 改造实施路径

## 项目概述

将 FoloUp 从 B2B HR 面试平台改造为 B2C 求职者面试练习平台的完整实施路径。

### 改造目标
- **从**: B2B HR 招聘面试平台（服务企业 HR）
- **到**: B2C 求职者面试练习平台（服务个人求职者）

---

## 阶段一：数据库架构重构 ✅

### 1.1 核心表结构调整

#### 完成的改动：
- [x] **用户模型转换**: 从组织依赖转为独立个人用户
- [x] **计费系统重构**: 实现灵活的基于使用量的订阅模式
- [x] **表重命名**: `interview` → `interview_session`, `response` → `interview_record`
- [x] **行业分类优化**: 从枚举改为字符串，提供更好的灵活性

#### 新增核心表：
- `plan`: 灵活的订阅计划管理
- `user_resume`: 多简历管理和 AI 优化
- `user_progress`: 用户学习进度追踪
- `job_application`: 求职申请跟踪（可选功能）

---

## 阶段二：前端界面改造

### 2.1 用户认证和注册

#### 目标用户界面调整：
- **注册流程**: 简化为个人用户注册，收集求职相关信息
- **用户资料**: 增加技能、经验年限、目标行业等字段
- **简历管理**: 多简历上传和管理界面

#### 实施要点：
```typescript
// 更新用户类型定义
interface User {
  id: string;
  email: string;
  full_name: string;
  current_plan_id: string;
  preferred_industries: string[];
  career_level: 'entry' | 'mid' | 'senior' | 'executive';
  skills: string[];
  experience_years: number;
}
```

### 2.2 订阅和计费界面

#### 计费页面重构：
- **定价展示**: 清晰的计划对比表格
- **使用量显示**: 当前已用面试次数和剩余次数
- **功能权限**: 根据计划显示可用功能

#### 关键组件：
- `PricingPlansComponent`: 计划选择和购买
- `UsageTrackingComponent`: 使用情况监控
- `PlanUpgradeModal`: 升级提醒和引导

### 2.3 主要功能页面改造

#### Dashboard 重新设计：
- **个人进度**: 面试完成情况、技能提升趋势
- **推荐内容**: 基于用户行业和技能的职位推荐
- **快速开始**: 一键创建面试会话

#### 面试功能优化：
- **简历选择**: 面试前选择使用哪份简历
- **职位匹配**: 选择目标职位进行针对性练习
- **个性化问题**: 基于简历和职位生成定制问题

---

## 阶段三：业务逻辑调整

### 3.1 面试会话管理

#### 会话创建流程：
1. 用户选择目标职位
2. 选择使用的简历
3. 选择面试官风格
4. 系统生成个性化问题
5. 开始面试会话

#### 核心服务调整：
```typescript
class InterviewSessionService {
  async createSession(params: {
    userId: string;
    jobId: number;
    resumeId: number;
    interviewerId: number;
    difficulty: 'easy' | 'medium' | 'hard';
  }): Promise<InterviewSession>

  async generateQuestions(
    resume: UserResume, 
    job: Job, 
    interviewer: Interviewer
  ): Promise<Question[]>
}
```

### 3.2 计费和权限控制

#### 使用量控制：
- 检查用户当前计划的面试次数限制
- 记录面试使用情况
- 触发升级提醒

#### 功能权限管理：
```typescript
class PlanPermissionService {
  canCreateInterview(user: User): boolean
  canAccessAdvancedAnalytics(user: User): boolean
  canUseCustomInterviewers(user: User): boolean
  getAvailableInterviewerPersonalities(user: User): string[]
}
```

### 3.3 AI 分析和反馈

#### 个性化分析：
- 基于简历内容分析回答相关性
- 针对目标职位提供改进建议
- 追踪用户在不同技能维度的进步

#### 反馈系统升级：
- 更详细的表现分析
- 具体的改进建议
- 推荐相关学习资源

---

## 阶段四：新功能开发

### 4.1 简历管理和优化

#### 简历管理功能：
- 多简历上传和存储
- AI 简历解析和结构化
- ATS 兼容性评分
- 针对特定职位的简历优化建议

#### 实施组件：
- `ResumeUploadComponent`: 简历上传和解析
- `ResumeEditorComponent`: 简历编辑和优化
- `ATSScoreComponent`: ATS 评分显示

### 4.2 职位库和匹配

#### 职位数据管理：
- 管理员添加热门职位
- 支持外部职位数据抓取
- 用户提交感兴趣的职位

#### 智能匹配：
- 基于用户技能和经验匹配合适职位
- 推荐相关的面试练习
- 追踪申请状态（可选功能）

### 4.3 学习进度和成就系统

#### 进度追踪：
- 面试完成情况统计
- 技能提升趋势分析
- 弱点识别和改进建议

#### 成就系统：
- 连续面试天数奖励
- 技能提升里程碑
- 分享成就到社交媒体

---

## 阶段五：性能优化和扩展

### 5.1 数据库优化

#### 索引策略：
- 用户相关查询优化
- 面试会话检索优化
- 职位搜索和过滤优化

#### 查询优化：
```sql
-- 优化用户面试历史查询
CREATE INDEX idx_interview_session_user_created ON interview_session(user_id, created_at DESC);

-- 优化职位搜索
CREATE INDEX idx_job_search ON job USING GIN(to_tsvector('english', job_title || ' ' || company_name));
```

### 5.2 缓存策略

#### Redis 缓存应用：
- 用户会话信息缓存
- 热门职位数据缓存
- 面试问题模板缓存
- 用户权限信息缓存

### 5.3 API 性能优化

#### 关键 API 优化：
- 面试会话创建接口
- 用户数据获取接口
- 实时面试状态更新
- 分析结果生成接口

---

## 阶段六：测试和部署

### 6.1 测试策略

#### 数据迁移测试：
- 验证 B2B 到 B2C 数据转换正确性
- 测试用户账户和面试记录完整性
- 验证计费系统准确性

#### 功能测试：
- 完整的用户注册到面试流程测试
- 不同计划权限控制测试
- 跨设备兼容性测试

### 6.2 逐步发布

#### 灰度发布策略：
1. **内部测试阶段**: 团队成员和少量邀请用户
2. **Beta 测试阶段**: 扩展到 100-500 用户
3. **软启动**: 开放注册但不做大规模推广
4. **正式发布**: 全面推广和营销

#### 监控指标：
- 用户注册转化率
- 面试完成率
- 付费转化率
- 用户留存率
- 系统性能指标

---

## 阶段七：运营和增长

### 7.1 内容运营

#### 职位库建设：
- 与招聘网站合作获取职位数据
- 行业专家审核职位质量
- 定期更新热门职位

#### 面试官扩展：
- 邀请行业专家录制面试风格
- 开发更多行业专业面试官
- 提供个性化面试官推荐

### 7.2 用户增长

#### 获客策略：
- SEO 优化（求职相关关键词）
- 内容营销（面试技巧、求职指南）
- 社交媒体推广
- 推荐奖励计划

#### 留存策略：
- 个性化面试建议推送
- 学习进度提醒
- 行业趋势分析报告
- 社区功能（用户分享和讨论）

---

## 预期时间表

| 阶段 | 预计时间 | 主要里程碑 |
|------|----------|------------|
| 阶段一 | 2 周 | 数据库架构完成 ✅ |
| 阶段二 | 3-4 周 | 前端界面改造完成 |
| 阶段三 | 2-3 周 | 核心业务逻辑调整 |
| 阶段四 | 4-5 周 | 新功能开发完成 |
| 阶段五 | 2 周 | 性能优化完成 |
| 阶段六 | 2-3 周 | 测试和初步部署 |
| 阶段七 | 持续 | 运营和增长优化 |

**总计**: 约 15-20 周完成核心改造，然后进入持续优化阶段。

---
