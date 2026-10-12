-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.databaseversion (
  version character varying NOT NULL,
  CONSTRAINT databaseversion_pkey PRIMARY KEY (version)
);
CREATE TABLE public.roles (
  roleid integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  rolename character varying NOT NULL,
  description character varying,
  CONSTRAINT roles_pkey PRIMARY KEY (roleid)
);
CREATE TABLE public.users (
  userid uuid NOT NULL DEFAULT gen_random_uuid(),
  username character varying UNIQUE,
  password text,
  firstname character varying,
  lastname character varying,
  roleid integer DEFAULT 1,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT users_pkey PRIMARY KEY (userid),
  CONSTRAINT rolefk FOREIGN KEY (roleid) REFERENCES public.roles(roleid)
);
CREATE TABLE public.product_types (
  typeid integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  typename text NOT NULL UNIQUE,
  CONSTRAINT product_types_pkey PRIMARY KEY (typeid)
);
CREATE TABLE public.products (
  productid integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  sku character varying,
  typeid integer,
  price numeric,
  imageurl character varying,
  CONSTRAINT products_pkey PRIMARY KEY (productid),
  CONSTRAINT rolefk FOREIGN KEY (typeid) REFERENCES public.product_types(typeid)
);
CREATE TABLE public.bitacora_users (
  bitacora_id integer NOT NULL DEFAULT nextval('bitacora_users_bitacora_id_seq'::regclass),
  userid uuid,
  username character varying,
  firstname character varying,
  lastname character varying,
  roleid integer,
  accion character varying,
  hecho_por uuid,
  fecha_hora timestamp without time zone DEFAULT now(),
  CONSTRAINT bitacora_users_pkey PRIMARY KEY (bitacora_id)
);
CREATE TABLE public.bitacora_products (
  id integer NOT NULL DEFAULT nextval('bitacora_products_id_seq'::regclass),
  productid integer,
  name character varying,
  sku character varying,
  typeid integer,
  price numeric,
  accion character varying,
  hecho_por uuid,
  fecha_hora timestamp without time zone DEFAULT now(),
  imageurl character varying,
  CONSTRAINT bitacora_products_pkey PRIMARY KEY (id)
);
CREATE TABLE public.inventory (
  inventoryid integer NOT NULL DEFAULT nextval('inventory_inventoryid_seq'::regclass),
  productid integer NOT NULL UNIQUE,
  stock integer NOT NULL DEFAULT 500 CHECK (stock >= 0),
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT inventory_pkey PRIMARY KEY (inventoryid),
  CONSTRAINT inventory_productid_fkey FOREIGN KEY (productid) REFERENCES public.products(productid)
);
CREATE TABLE public.shifts (
  shiftid integer NOT NULL DEFAULT nextval('shifts_shiftid_seq'::regclass),
  cashierid uuid NOT NULL,
  opening_amount numeric NOT NULL CHECK (opening_amount >= 0::numeric),
  status character varying NOT NULL DEFAULT 'OPEN'::character varying,
  opened_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  closed_at timestamp with time zone,
  CONSTRAINT shifts_pkey PRIMARY KEY (shiftid),
  CONSTRAINT shifts_cashierid_fkey FOREIGN KEY (cashierid) REFERENCES public.users(userid)
);
CREATE TABLE public.sales (
  saleid integer NOT NULL DEFAULT nextval('sales_saleid_seq'::regclass),
  shiftid integer NOT NULL,
  cashierid uuid NOT NULL,
  total numeric NOT NULL CHECK (total >= 0::numeric),
  status character varying NOT NULL DEFAULT 'COMPLETED'::character varying,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT sales_pkey PRIMARY KEY (saleid),
  CONSTRAINT sales_shiftid_fkey FOREIGN KEY (shiftid) REFERENCES public.shifts(shiftid),
  CONSTRAINT sales_cashierid_fkey FOREIGN KEY (cashierid) REFERENCES public.users(userid)
);
CREATE TABLE public.sale_items (
  saleitemid integer NOT NULL DEFAULT nextval('sale_items_saleitemid_seq'::regclass),
  saleid integer NOT NULL,
  productid integer NOT NULL,
  unit_price numeric NOT NULL CHECK (unit_price >= 0::numeric),
  quantity integer NOT NULL CHECK (quantity > 0),
  subtotal numeric NOT NULL CHECK (subtotal >= 0::numeric),
  CONSTRAINT sale_items_pkey PRIMARY KEY (saleitemid),
  CONSTRAINT sale_items_saleid_fkey FOREIGN KEY (saleid) REFERENCES public.sales(saleid),
  CONSTRAINT sale_items_productid_fkey FOREIGN KEY (productid) REFERENCES public.products(productid)
);
CREATE TABLE public.z_cuts (
  zcutid integer NOT NULL DEFAULT nextval('z_cuts_zcutid_seq'::regclass),
  shiftid integer NOT NULL UNIQUE,
  cashierid uuid NOT NULL,
  opened_at timestamp with time zone NOT NULL,
  closed_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  firstsaleid integer,
  lastsaleid integer,
  opening_cash numeric NOT NULL,
  total_sales numeric NOT NULL,
  total_sales_count integer NOT NULL DEFAULT 0,
  expected_cash numeric NOT NULL,
  expected_card numeric NOT NULL DEFAULT 0.00,
  expected_transfer numeric NOT NULL DEFAULT 0.00,
  actual_cash numeric NOT NULL,
  cash_difference numeric NOT NULL,
  notes text,
  CONSTRAINT z_cuts_pkey PRIMARY KEY (zcutid),
  CONSTRAINT z_cuts_shiftid_fkey FOREIGN KEY (shiftid) REFERENCES public.shifts(shiftid),
  CONSTRAINT z_cuts_cashierid_fkey FOREIGN KEY (cashierid) REFERENCES public.users(userid),
  CONSTRAINT z_cuts_firstsaleid_fkey FOREIGN KEY (firstsaleid) REFERENCES public.sales(saleid),
  CONSTRAINT z_cuts_lastsaleid_fkey FOREIGN KEY (lastsaleid) REFERENCES public.sales(saleid)
);
CREATE TABLE public.salepayments (
  paymentid integer NOT NULL DEFAULT nextval('salepayments_paymentid_seq'::regclass),
  saleid integer NOT NULL,
  payment_method character varying NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0::numeric),
  amount_given numeric,
  change_given numeric,
  transaction_reference character varying,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT salepayments_pkey PRIMARY KEY (paymentid),
  CONSTRAINT salepayments_saleid_fkey FOREIGN KEY (saleid) REFERENCES public.sales(saleid)
);
CREATE TABLE public.bitacora_sales (
  bitacora_id integer NOT NULL DEFAULT nextval('bitacora_sales_bitacora_id_seq'::regclass),
  saleid integer,
  shiftid integer,
  cashierid uuid,
  total numeric,
  status text,
  created_at timestamp without time zone,
  hecho_por uuid,
  fecha_hora timestamp without time zone DEFAULT now(),
  accion character varying,
  CONSTRAINT bitacora_sales_pkey PRIMARY KEY (bitacora_id)
);
CREATE TABLE public.bitacora_shift (
  bitacora_id integer NOT NULL DEFAULT nextval('bitacora_shift_bitacora_id_seq'::regclass),
  shiftid integer,
  cashierid uuid,
  opening_amount numeric,
  status text,
  opened_at timestamp without time zone,
  closed_at timestamp without time zone,
  accion character varying,
  hecho_por uuid,
  fecha_hora timestamp without time zone DEFAULT now(),
  CONSTRAINT bitacora_shift_pkey PRIMARY KEY (bitacora_id)
);
CREATE TABLE public.bitacora_z_cuts (
  bitacora_id integer NOT NULL DEFAULT nextval('bitacora_z_cuts_bitacora_id_seq'::regclass),
  zcutid integer,
  shiftid integer,
  cashierid uuid,
  opened_at timestamp without time zone,
  closed_at timestamp without time zone,
  firstsaleid integer,
  lastsaleid integer,
  opening_cash numeric,
  total_sales numeric,
  total_sales_count integer,
  expected_cash numeric,
  expected_card numeric,
  expected_transfer numeric,
  actual_cash numeric,
  cash_difference numeric,
  notes text,
  accion character varying,
  hecho_por uuid,
  fecha_hora timestamp without time zone DEFAULT now(),
  CONSTRAINT bitacora_z_cuts_pkey PRIMARY KEY (bitacora_id)
);
CREATE TABLE public.bitacora_inventory (
  bitacora_id integer NOT NULL DEFAULT nextval('bitacora_inventory_bitacora_id_seq'::regclass),
  inventoryid integer,
  productid integer,
  stock integer,
  updated_at timestamp without time zone,
  accion character varying,
  hecho_por uuid,
  fecha_hora timestamp without time zone DEFAULT now(),
  CONSTRAINT bitacora_inventory_pkey PRIMARY KEY (bitacora_id)
);