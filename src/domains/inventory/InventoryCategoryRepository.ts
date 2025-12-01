import { InventoryCategory } from './InventoryCategory';

export interface InventoryCategoryRepository {
  findById(id: string): Promise<InventoryCategory | null>;

  /**
   * Top-level categories (no parent)
   */
  listRootCategories(): Promise<InventoryCategory[]>;

  /**
   * Direct children of a given category.
   * Use parentId = null to list roots if you want one method for both.
   */
  listChildren(parentId: string | null): Promise<InventoryCategory[]>;

  /**
   * Optional: lookup by code (e.g. 'JEWELRY', 'FIREARM').
   */
  findByCode(code: string): Promise<InventoryCategory | null>;
}
