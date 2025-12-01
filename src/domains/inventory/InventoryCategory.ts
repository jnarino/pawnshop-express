export class InventoryCategory {
  readonly id: string;

  name: string;
  code: string;
  parentId: string | null;
  /** ltree path stored as a string, e.g. "JEWELRY.RING" */
  path: string | null;
  /** Derived from ltree in the DB, but we keep it as number here */
  depth: number;

  createdAt: Date;
  updatedAt: Date;

  constructor(params: {
    id: string;
    name: string;
    code: string;
    parentId?: string | null;
    path?: string | null;
    depth: number;
    createdAt: Date;
    updatedAt: Date;
  }) {
    this.id = params.id;

    this.name = params.name;
    this.code = params.code;
    this.parentId = params.parentId ?? null;
    this.path = params.path ?? null;
    this.depth = params.depth;

    this.createdAt = params.createdAt;
    this.updatedAt = params.updatedAt;
  }
}
