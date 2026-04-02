/**
 * Enhanced Admin Tools
 * Advanced admin utilities for data management and batch operations
 */

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Filter, Download, Trash2, CheckCircle2, X } from 'lucide-react';
import { cn } from '@/lib/utils';

interface AdminDataRow {
  id: string;
  [key: string]: any;
}

interface AdminTableProps {
  data: AdminDataRow[];
  columns: Array<{ key: string; label: string; render?: (value: any) => React.ReactNode }>;
  onDelete?: (id: string) => void;
  selectable?: boolean;
  searchable?: boolean;
  sortable?: boolean;
  filterable?: boolean;
}

export const AdminDataTable = ({
  data,
  columns,
  onDelete,
  selectable = true,
  searchable = true,
  sortable = true,
  filterable = true,
}: AdminTableProps) => {
  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set());
  const [searchTerm, setSearchTerm] = useState('');
  const [sortKey, setSortKey] = useState<string | null>(null);
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc');
  const [filters, setFilters] = useState<Record<string, string>>({});

  // Filter and sort data
  const filteredData = useMemo(() => {
    let result = [...data];

    // Search filter
    if (searchTerm && searchable) {
      result = result.filter((row) =>
        Object.values(row).some((v) =>
          String(v).toLowerCase().includes(searchTerm.toLowerCase())
        )
      );
    }

    // Sort
    if (sortKey && sortable) {
      result.sort((a, b) => {
        const aVal = a[sortKey];
        const bVal = b[sortKey];
        const cmp = String(aVal).localeCompare(String(bVal));
        return sortDir === 'asc' ? cmp : -cmp;
      });
    }

    return result;
  }, [data, searchTerm, sortKey, sortDir, searchable, sortable]);

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedRows(new Set(filteredData.map((r) => r.id)));
    } else {
      setSelectedRows(new Set());
    }
  };

  const handleSelectRow = (id: string) => {
    const newSelected = new Set(selectedRows);
    newSelected.has(id) ? newSelected.delete(id) : newSelected.add(id);
    setSelectedRows(newSelected);
  };

  const handleDeleteSelected = async () => {
    for (const id of selectedRows) {
      await onDelete?.(id);
    }
    setSelectedRows(new Set());
  };

  const handleExport = () => {
    const csv = [
      columns.map((c) => c.label).join(','),
      ...filteredData.map((row) =>
        columns.map((c) => `"${row[c.key]}"`).join(',')
      ),
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'export.csv';
    a.click();
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-4"
    >
      {/* Controls */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
        {searchable && (
          <div className="relative flex-1 max-w-xs">
            <Search className="absolute left-3 top-3 w-4 h-4 text-gray-500" />
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-3 py-2 rounded-lg bg-slate-900/50 border border-white/10 text-white placeholder-gray-500 focus:border-blue-500/50 focus:ring-2 focus:ring-blue-500/40 transition-all"
            />
          </div>
        )}

        <div className="flex gap-2">
          {selectedRows.size > 0 && (
            <motion.button
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              onClick={handleDeleteSelected}
              className="px-3 py-2 rounded-lg bg-rose-600/20 text-rose-400 hover:bg-rose-600/30 transition-all flex items-center gap-2 text-sm"
            >
              <Trash2 className="w-4 h-4" />
              Delete ({selectedRows.size})
            </motion.button>
          )}
          
          <button
            onClick={handleExport}
            className="px-3 py-2 rounded-lg bg-emerald-600/20 text-emerald-400 hover:bg-emerald-600/30 transition-all flex items-center gap-2 text-sm"
          >
            <Download className="w-4 h-4" />
            Export
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="card-polished overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b border-white/10">
            <tr>
              {selectable && (
                <th className="p-3 text-left font-semibold text-gray-400 w-12">
                  <input
                    type="checkbox"
                    checked={selectedRows.size === filteredData.length && filteredData.length > 0}
                    onChange={(e) => handleSelectAll(e.target.checked)}
                    className="w-4 h-4 rounded cursor-pointer"
                  />
                </th>
              )}
              {columns.map((col) => (
                <th
                  key={col.key}
                  onClick={() => {
                    if (sortable) {
                      setSortKey(col.key);
                      setSortDir(sortKey === col.key && sortDir === 'asc' ? 'desc' : 'asc');
                    }
                  }}
                  className={cn(
                    'p-3 text-left font-semibold text-gray-400',
                    sortable && 'cursor-pointer hover:text-white transition'
                  )}
                >
                  {col.label}
                  {sortable && sortKey === col.key && (
                    <span className="ml-1">{sortDir === 'asc' ? '↑' : '↓'}</span>
                  )}
                </th>
              ))}
              {onDelete && <th className="p-3 text-center font-semibold text-gray-400 w-12">Actions</th>}
            </tr>
          </thead>
          <tbody>
            <AnimatePresence>
              {filteredData.map((row) => (
                <motion.tr
                  key={row.id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="border-b border-white/5 hover:bg-white/5 transition"
                >
                  {selectable && (
                    <td className="p-3">
                      <input
                        type="checkbox"
                        checked={selectedRows.has(row.id)}
                        onChange={() => handleSelectRow(row.id)}
                        className="w-4 h-4 rounded cursor-pointer"
                      />
                    </td>
                  )}
                  {columns.map((col) => (
                    <td key={col.key} className="p-3 text-gray-300">
                      {col.render ? col.render(row[col.key]) : row[col.key]}
                    </td>
                  ))}
                  {onDelete && (
                    <td className="p-3 text-center">
                      <button
                        onClick={() => onDelete(row.id)}
                        className="text-rose-400 hover:text-rose-300 transition"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  )}
                </motion.tr>
              ))}
            </AnimatePresence>
          </tbody>
        </table>
      </div>

      {/* No results */}
      {filteredData.length === 0 && (
        <div className="text-center p-8 text-gray-400">
          No records found
        </div>
      )}
    </motion.div>
  );
};

/**
 * Batch Actions Component
 */
interface BatchAction {
  label: string;
  color?: 'primary' | 'danger' | 'success';
  onClick: (selectedIds: string[]) => Promise<void>;
}

interface BatchActionsProps {
  selectedIds: string[];
  actions: BatchAction[];
  loading?: boolean;
}

export const BatchActions = ({ selectedIds, actions, loading }: BatchActionsProps) => (
  <AnimatePresence>
    {selectedIds.length > 0 && (
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: 10 }}
        className="fixed bottom-24 left-4 right-4 card-polished p-4 flex gap-2 flex-wrap"
      >
        {actions.map((action) => (
          <button
            key={action.label}
            onClick={() => action.onClick(selectedIds)}
            disabled={loading}
            className={cn(
              'px-4 py-2 rounded-lg font-semibold text-sm transition-all',
              action.color === 'danger' && 'bg-rose-600/20 text-rose-400 hover:bg-rose-600/30',
              action.color === 'success' && 'bg-emerald-600/20 text-emerald-400 hover:bg-emerald-600/30',
              !action.color && 'bg-blue-600/20 text-blue-400 hover:bg-blue-600/30',
              loading && 'opacity-50 cursor-not-allowed'
            )}
          >
            {action.label}
          </button>
        ))}
      </motion.div>
    )}
  </AnimatePresence>
);
