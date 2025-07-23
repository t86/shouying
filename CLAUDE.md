# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Vue.js 2.x restaurant/karaoke management system (收银/点餐管理系统) that handles table booking, ordering, payments, inventory, and customer management. The application serves multiple business modules through a single-page application architecture.

## Development Commands

### Installation and Setup
```bash
npm install                    # Install dependencies
```

### Development
```bash
npm run serve                  # Start development server on port 8090
```

### Build Commands
```bash
npm run build                  # Standard production build
npm run build-dev              # Development environment build with versioning
npm run build-local            # Local environment build with versioning
npm run prod                   # Production build for store deployment (optimized)
npm run version                # Generate version.json file
```

### Environment Configuration
- Development: `.env.development`
- Production: `.env.production` 
- Local: `.env.local`
- Store: `.env.store`

## Architecture Overview

### Business Module Structure

The application is organized into 6 main business modules, each with dedicated routes, views, and API services:

1. **BMS (Business Management System)** - Backend store management
   - Product/employee management, device configuration
   - Table management, pricing, reports

2. **ERP System** - Inventory and supply chain
   - Material/supplier management, warehouse operations
   - Stock monitoring and reports

3. **Order System** - Customer ordering interface
   - Product catalog, shopping cart, table-based ordering
   - Meal combinations, order printing

4. **Money/Payment System** - Financial operations
   - Payment processing, cash management
   - Daily reports, transaction history

5. **VIP System** - Customer relationship management
   - Member registration, points system
   - Loyalty programs, consumption tracking

6. **Wine Storage System** - Specialized wine inventory
   - Wine storage for customers, retrieval and aging tracking

### Key Directories

```
/src/
├── router/           # Modular route configuration by business domain
├── store/           # Vuex state management with sessionStorage persistence
├── views/           # Page components organized by business function
├── api/             # API services organized by business domain
├── utils/           # Utilities, HTTP configuration, helpers
├── components/      # Reusable UI components
└── style/           # Global styles (Less + TailwindCSS)
```

### Technical Stack

- **Frontend**: Vue.js 2.6.11 + Element UI 2.15.8
- **State Management**: Vuex 3.4.0 with sessionStorage persistence
- **Styling**: TailwindCSS + Less + Element UI components
- **Build**: Vue CLI 4.5.0 with custom webpack optimizations
- **Special Features**: Print system, QR codes, clipboard, mobile debugging (VConsole)

## User Role System

The system uses a role-based permission structure with 11 defined roles:

- 咨客 (Guest Services)
- 服务员 (Waiter) 
- 营销 (Marketing)
- 特饮 (Beverage Specialist)
- 收银员 (Cashier)
- 系统管理员 (System Admin)
- 会员中心 (Member Center)
- ERP管理员 (ERP Admin)
- 仓库管理员 (Warehouse Manager)
- 存酒仓管理员 (Wine Storage Manager)
- 督查 (Supervisor)

Each role has specific module permissions defined in `sys_role_modules` configuration.

## Entity Types

### Table Types (卡台类型)
- 1: 实体台 (Physical Table)
- 2: 虚拟台 (Virtual Table) 
- 3: 关联功能台 (Associated Function Table)
- 4: 功能台 (Function Table)

### Product Types (商品类型)
- 1: 普通单品 (Regular Item)
- 2: 套餐 (Set Menu)
- 3: 时价特饮 (Time-based Beverage)
- 4: 时价小费 (Time-based Tips)
- 5: 时价赔偿 (Time-based Compensation)
- 6: 联营 (Joint Venture)
- 13: 定价特饮 (Fixed Price Beverage)
- 14: 定价小费 (Fixed Price Tips) 
- 15: 定价赔偿 (Fixed Price Compensation)

## Development Notes

### Performance Optimizations
- Route-based code splitting with lazy loading
- Aggressive chunk optimization (framework/vendor/initial splits)
- Bundle size monitoring with configured limits
- Image optimization with url-loader

### API Organization
APIs are organized by business domain under `/src/api/`. Each module has dedicated service files following a consistent pattern for CRUD operations.

### State Management
Uses Vuex with modules corresponding to business domains. State is persisted to sessionStorage for user session continuity.

### Print System Integration
The application includes specialized print functionality for receipts and orders using `vue-print-nb`. Print templates are configured per business requirement.

### Mobile Support
Includes VConsole for mobile debugging and touch-optimized interfaces for tablet/mobile ordering scenarios.

## Deployment

The application uses Docker for deployment with nginx serving the built static files. Use `./deploy.sh` for automated build and deployment process.