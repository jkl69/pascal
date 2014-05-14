unit ArrayList;

INTERFACE

const
  VERSION = '0.2';

type
  pTArrayItem = ^TArrayItem;
  pTArrayList = ^TArrayList;
  TArrayItem = record
		prev: pTArrayItem;
		data: Pointer;
		next: pTArrayItem;
		end;
//  TArrayList = object
   TArrayList = class(Tobject)
		first: pTArrayItem;
		last:  pTArrayItem;
		datatype: string;
		typesize: integer;
		len:   integer;
		constructor Create(typename: string; size: integer);
		destructor Destroy();
		procedure Add(data: Pointer);
		procedure Put(index: integer; data: Pointer);
		procedure Del(index: integer);
		procedure Clear();
		procedure Switch(index1, index2: integer);
		procedure MoveItem(index, where: integer);
		procedure Join(l: pTArrayList);
		function GetItem(index: integer): pTArrayItem;
		function Get(index: integer): Pointer;
		function Empty(): boolean;
		function Created(): boolean;
		function Pop(): Pointer;
		function Clone(index, size: integer): pTArrayList;
		end;

function CopyData(const data: Pointer; size: integer): Pointer;
function Explode(s: string; ch: char): pTArrayList;
function Split(s: string; len: integer): pTArrayList;
function Join(l: pTArrayList): string;

IMPLEMENTATION

{ Initialize the list for use.
  typename: a type of stored values
  size: an amount of memory needed to store the type (use sizeof()) }
constructor TArrayList.Create(typename: string; size: integer);
var
  item: pTArrayItem;
begin
  new(item);
  item^.prev := nil;
  item^.data := nil;
  item^.next := nil;

  first := item;
  last  := item;
  datatype := typename;
  typesize := size;
  len   := 0;
end;

{ Free all used memory, delete items and deinitialize the list. }
destructor TArrayList.Destroy();
var
  r: pTArrayItem;
begin
  while first <> nil do	
  begin
    r := first;
    first := first^.next;
    FreeMem(r^.data, sizeof(typesize));  { Delete the data stored in the item }
    Dispose(r);  { Delete the item }
  end;
  last  := nil;
  datatype := '';
  len   := -1;
end;

procedure RaiseRangeError();
begin
  writeln('Error! The value is out of the range.');
end;

{ Insert a 'data' into the list at the 'index' position.
  index: 0..len
  data: pointer to a data to store }
procedure TArrayList.Put(index: integer; data: Pointer);
var
  item, p, q: pTArrayItem;
  i: integer;
begin
  if (index > len) or (index < 0) then
  begin
    RaiseRangeError();
    exit;
  end;

  new(item);
  item^.data := data;
  p := first;
  for i := 0 to index - 1 do
    p := p^.next;
  q := p^.prev;

  item^.prev := q;
  item^.next := p;
  p^.prev := item;
  if q <> nil then q^.next := item;
  if index = 0 then first := item;
  if index = len then last := p;
  Inc(len);
end;

{ Add a 'data' at the end of list. }
procedure TArrayList.Add(data: Pointer);
var
  p, c: pTArrayItem;
begin
  p := last^.prev;
  new(c);
  c^.data := data;
  c^.prev := p;
  c^.next := last;
  last^.prev := c;
  if p <> nil then p^.next := c
  else first := c;
  Inc(len);
end;

{ Return an item from the list at the 'index' position. }
function TArrayList.GetItem(index: integer): pTArrayItem;
var
  p: pTArrayItem;
  i: integer;
begin
  if (index >= len) or (index < 0) then
  begin
    RaiseRangeError();
    exit;
  end;

  if index <= len div 2 then
  begin
    p := first;
    for i := 0 to index - 1 do
      p := p^.next;
  end
  else
  begin 
    p := last;
    for i := 0 to len - index - 1 do
      p := p^.prev;
  end;

  GetItem := p;
end;

{ Return a data of the item at the 'index'. }
function TArrayList.Get(index: integer): Pointer;
begin
  Get := GetItem(index)^.data;
end;

{ Delete an item (and a data) at the 'index' position. }
procedure TArrayList.Del(index: integer);
var
  p, q, n: pTArrayItem;
  i: integer;
begin
  if (index >= len) or (index < 0) then
  begin
    RaiseRangeError();
    exit;
  end;
  
  p := first;
  for i := 0 to index - 1 do
    p := p^.next;
  q := p^.prev;
  n := p^.next;

  n^.prev := q;
  if q <> nil then q^.next := n;
  if index = 0 then first := n;
  FreeMem(p^.data, sizeof(typesize));
  Dispose(p);
  Dec(len);
end;

{ Clone data in the heap. }
function CopyData(const data: Pointer; size: integer): Pointer;
var
  n: Pointer;
begin
  n := AllocMem(size);
  Move(data^, n^, size);
  CopyData := n;
end;  

function TArrayList.Empty(): boolean;
begin
  if len > 0 then Empty := false
  else Empty := true;
end;

function TArrayList.Created(): boolean;
begin
 if (len > -1) and (datatype <> '') then Created := true
 else Created := false;
end;

{ Return a copy of data from the end of the list and deletes the item. }
function TArrayList.Pop(): Pointer;
var
  p: Pointer;
begin
  if Empty() then Pop := nil else
  begin
    p := CopyData(Get(len - 1), typesize);
    Del(len - 1);
    Pop := p;
  end;
end;

{ Slice the list (index..index + size - 1) and return a copy of the slice. }
function TArrayList.Clone(index, size: integer): pTArrayList;
var
  n: pTArrayList;
  p, q: pTArrayItem;
  i: integer;
begin
  if (index < 0) or (size < 0) or (index + size > len) then
  begin
    RaiseRangeError();
    exit;
  end;

  new(n);
  n^.Create(datatype, typesize);
  for i := index to index + size - 1 do
    n^.Add(CopyData(Get(i), typesize));

  Clone := n;
end;

{ Swap data in two items. }
procedure TArrayList.Switch(index1, index2: integer);
var
  d: Pointer;
  a, b: pTArrayItem;
begin
  if ((index1 < 0) or (index1 >= len)) or ((index2 < 0) or (index2 >= len)) then
  begin
    RaiseRangeError();
    exit;
  end;

  a := GetItem(index1);
  b := GetItem(index2);
  d := a^.data;
  a^.data := b^.data;
  b^.data := d;
end;

{ Move an item at the 'index' position to the 'where' position. }
procedure TArrayList.MoveItem(index, where: integer);
var
  p1, c1, n1, c2: pTArrayItem;
begin
  if ((index < 0) or (index >= len)) or ((where < 0) or (where > len)) then
  begin
    RaiseRangeError();
    exit;
  end;

  c1 := GetItem(index);
  p1 := c1^.prev;
  n1 := c1^.next;
  if where = len then c2 := last else c2 := GetItem(where);

  n1^.prev := p1;
  if p1 <> nil then p1^.next := n1;
  if index = 0 then first := n1;

  c1^.prev := c2^.prev;
  c1^.next := c2;
  c1^.next^.prev := c1;
  if c1^.prev <> nil then c1^.prev^.next := c1;
  if where = 0 then first := c1;
end;

{ Empty the list. }
procedure TArrayList.Clear();
begin
  while not Empty() do
    Del(0);
end;

{ Add the 'l' list to the end of list. The 'l' list must be created 
  and the same type as the list. }
procedure TArrayList.Join(l: pTArrayList);
var
  i: integer;
begin
  if (not l^.Created()) and (l^.datatype <> datatype) then 
  begin
    writeln('An invalid list.');
    exit;
  end;

  for i := 0 to l^.len do
    Add(CopyData(l^.Get(i), typesize));
end;

{ Split the 's' string by 'ch' character into a list. (Not a very elegant func.) }
function Explode(s: string; ch: char): pTArrayList;
var
  l: pTArrayList;
  pstr: ^string;
begin
{
if s[1] <> ch then s := ch + s;
  if s[length(s)] <> ch then s := s + ch;

  new(l, Create('string', sizeof(string)));
  while length(s) <> 1 do
  begin
    Delete(s, 1, 1);
    new(pstr);
    pstr^ := Copy(s, 1, Pos(ch, s) - 1);
    l^.Add(pstr);
    Delete(s, 1, Pos(ch, s) - 1);
  end;

  Explode := l;
  }
end;

function Split(s: string; len: integer): pTArrayList;
var 
  l: pTArrayList;
  pstr: ^string;
begin
{
new(l, Create('string', sizeof(string)));

  if len > 0 then
    while length(s) <> 0 do
    begin
      new(pstr);
      pstr^ := Copy(s, 1, len);
      l^.Add(pstr);
      Delete(s, 1, len);
    end;

  Split := l;
  }
end;

function Join(l: pTArrayList): string;
var
  s: string;
  pstr: ^string;
  i: integer;
begin
  s := '';
  if l^.datatype <> 'string' then Join := '';

  for i := 0 to l^.len - 1 do
  begin
    pstr := l^.Get(i);
    s := s + pstr^;
  end;

  Join := s;
end;

BEGIN
END.
