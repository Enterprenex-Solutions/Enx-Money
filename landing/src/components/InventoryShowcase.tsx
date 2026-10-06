import React from 'react';
import { 
  AlertTriangle, 
  CheckCircle2, 
  Boxes, 
  BarChart3
} from 'lucide-react';

interface ProductItem {
  id: string;
  name: string;
  category: string;
  currentStock: number;
  unit: string;
  reorderLevel: number;
  purchasePrice: number;
  sellingPrice: number;
  isLowStock: boolean;
}

const SAMPLE_PRODUCTS: ProductItem[] = [
  {
    id: 'P-101',
    name: 'Industrial Copper Wiring 2.5mm',
    category: 'Electricals',
    currentStock: 120,
    unit: 'Coils',
    reorderLevel: 30,
    purchasePrice: 1250,
    sellingPrice: 1680,
    isLowStock: false,
  },
  {
    id: 'P-102',
    name: 'Aluminium Conduit Pipe 1-inch',
    category: 'Hardware',
    currentStock: 14,
    unit: 'Bundles',
    reorderLevel: 25,
    purchasePrice: 320,
    sellingPrice: 450,
    isLowStock: true,
  },
  {
    id: 'P-103',
    name: 'LED Modular Panel 18W (6500K)',
    category: 'Lighting',
    currentStock: 240,
    unit: 'Units',
    reorderLevel: 50,
    purchasePrice: 280,
    sellingPrice: 420,
    isLowStock: false,
  },
  {
    id: 'P-104',
    name: 'PVC Modular Junction Box 4-Way',
    category: 'Fittings',
    currentStock: 8,
    unit: 'Boxes',
    reorderLevel: 20,
    purchasePrice: 85,
    sellingPrice: 135,
    isLowStock: true,
  },
];

export const InventoryShowcase: React.FC = () => {
  return (
    <section className="py-24 bg-slate-50/70 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Heading */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-navy-50 border border-navy-100 text-navy-800 text-xs font-semibold tracking-wide">
            <Boxes className="w-3.5 h-3.5 text-emerald-600" />
            <span>INTELLIGENT STOCK CONTROL</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-navy-950 font-display tracking-tight">
            Know What You Have. Know What You Need.
          </h2>

          <p className="text-base sm:text-lg text-slate-600 font-normal leading-relaxed">
            Stop losing money on dead stock or lost sales. ENX Money tracks every unit across purchase orders and customer bills, giving you instant stock valuation and automated reorder alerts.
          </p>
        </div>

        {/* 2-Column Showcase */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          
          {/* Left Column: Product Cards Grid (7 Cols) */}
          <div className="lg:col-span-7 grid grid-cols-1 sm:grid-cols-2 gap-4">
            {SAMPLE_PRODUCTS.map((product) => {
              const marginPercent = Math.round(
                ((product.sellingPrice - product.purchasePrice) / product.purchasePrice) * 100
              );

              return (
                <div
                  key={product.id}
                  className={`bg-white rounded-2xl p-5 border shadow-sm transition-all duration-300 hover:shadow-md ${
                    product.isLowStock
                      ? 'border-amber-200/90 bg-amber-50/20'
                      : 'border-slate-200/90'
                  }`}
                >
                  {/* Top Category & Status */}
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                      {product.category}
                    </span>

                    {product.isLowStock ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800 border border-amber-200">
                        <AlertTriangle className="w-3 h-3 text-amber-600" />
                        <span>Low Stock</span>
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                        <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                        <span>Healthy</span>
                      </span>
                    )}
                  </div>

                  {/* Product Name */}
                  <h3 className="text-sm font-bold text-navy-950 font-display mb-3 line-clamp-1">
                    {product.name}
                  </h3>

                  {/* Stock Level Display */}
                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 mb-4">
                    <div className="text-[10px] text-slate-500 font-medium">Available Units</div>
                    <div className="text-2xl font-extrabold text-navy-950 font-display mt-0.5">
                      {product.currentStock}{' '}
                      <span className="text-xs font-normal text-slate-500">{product.unit}</span>
                    </div>
                    {product.isLowStock && (
                      <div className="text-[10px] text-amber-700 font-semibold mt-1">
                        Reorder Threshold: {product.reorderLevel} {product.unit}
                      </div>
                    )}
                  </div>

                  {/* Purchase vs Sell Rates */}
                  <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
                    <div>
                      <span className="text-slate-400 block text-[10px]">Buy Price</span>
                      <span className="font-semibold text-slate-700">₹{product.purchasePrice.toLocaleString()}</span>
                    </div>

                    <div className="text-right">
                      <span className="text-slate-400 block text-[10px]">Sell Price</span>
                      <span className="font-bold text-navy-950">₹{product.sellingPrice.toLocaleString()}</span>
                    </div>

                    <div className="text-right">
                      <span className="text-slate-400 block text-[10px]">Margin</span>
                      <span className="font-bold text-emerald-700">+{marginPercent}%</span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Right Column: Inventory Value & Analytics Chart (5 Cols) */}
          <div className="lg:col-span-5 bg-white rounded-3xl p-6 sm:p-8 border border-slate-200 shadow-premium space-y-6">
            
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div>
                <h3 className="text-base font-bold text-navy-950">Stock Valuation & Breakdown</h3>
                <p className="text-xs text-slate-500">Live asset value calculated via FIFO</p>
              </div>
              <div className="w-9 h-9 rounded-xl bg-navy-50 text-navy-900 flex items-center justify-center">
                <BarChart3 className="w-5 h-5 text-emerald-600" />
              </div>
            </div>

            {/* Total Stock Value Card */}
            <div className="bg-gradient-to-br from-navy-950 to-navy-900 text-white p-5 rounded-2xl border border-navy-800 shadow">
              <div className="text-xs text-slate-400 font-medium">Total Current Stock Value</div>
              <div className="text-3xl font-extrabold text-emerald-400 font-display mt-1">
                ₹14,80,000
              </div>
              <div className="text-xs text-slate-300 mt-2 flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
                <span>Across 94 SKUs and 4 warehouses</span>
              </div>
            </div>

            {/* Category Breakdown Bars */}
            <div className="space-y-4">
              <div className="text-xs font-bold text-navy-950 uppercase tracking-wider">
                Category Distribution
              </div>

              <div>
                <div className="flex justify-between text-xs font-medium text-slate-700 mb-1">
                  <span>Electrical Components</span>
                  <span className="font-bold">48% (₹7,10,400)</span>
                </div>
                <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                  <div className="h-full bg-emerald-500 rounded-full w-[48%]" />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-medium text-slate-700 mb-1">
                  <span>Hardware & Metals</span>
                  <span className="font-bold">32% (₹4,73,600)</span>
                </div>
                <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                  <div className="h-full bg-navy-800 rounded-full w-[32%]" />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-medium text-slate-700 mb-1">
                  <span>Lighting & Panels</span>
                  <span className="font-bold">20% (₹2,96,000)</span>
                </div>
                <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                  <div className="h-full bg-cyan-500 rounded-full w-[20%]" />
                </div>
              </div>
            </div>

            {/* Quick Tip */}
            <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-100 text-xs text-slate-600 leading-relaxed">
              <span className="font-bold text-navy-950">Fast Stock Search:</span> Connect any Bluetooth or USB barcode scanner directly to the ENX Money app for 1-second item addition at the counter.
            </div>

          </div>

        </div>

      </div>
    </section>
  );
};
