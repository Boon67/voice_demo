from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime


class Customer(BaseModel):
    customer_id: int
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    loyalty_tier: Optional[str] = None
    address: Optional[str] = None


class Product(BaseModel):
    product_id: int
    name: str
    category: Optional[str] = None
    price: Optional[float] = None
    sku: Optional[str] = None


class OrderItem(BaseModel):
    product_name: str
    quantity: int
    price: float


class Order(BaseModel):
    order_id: int
    order_number: str
    order_date: Optional[str] = None
    status: Optional[str] = None
    total: Optional[float] = None
    tracking_number: Optional[str] = None
    items: List[OrderItem] = []


class CustomerDetail(BaseModel):
    customer: Customer
    orders: List[Order] = []


class ProductMatch(BaseModel):
    product_name: str
    category: Optional[str] = None
    price: Optional[float] = None
    sku: Optional[str] = None
    quantity: int = 1
    order_number: str = ""
    order_status: Optional[str] = None
    order_date: Optional[str] = None
    tracking_number: Optional[str] = None
    match_score: float = 0.0


class SimilarCase(BaseModel):
    case_number: str
    customer_name: Optional[str] = None
    product_name: Optional[str] = None
    case_type: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    issue_description: Optional[str] = None
    resolution: Optional[str] = None
    opened_date: Optional[str] = None
    match_score: float = 0.0


class CandidateValue(BaseModel):
    field_name: str
    field_value: str


class CallStatus(BaseModel):
    call_id: Optional[str] = None
    case_id: Optional[int] = None
    is_recording: bool = False
    chunk_count: int = 0
    full_transcript: str = ""


class SimulateRequest(BaseModel):
    text: str
    call_id: Optional[str] = None


class SearchRequest(BaseModel):
    query: str


class PlayRequest(BaseModel):
    recording_id: str = "demo_call"
