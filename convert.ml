open Ast

type out = string -> unit

module S = Set.Make(String)

let keywords = [
  "and"; "as"; "assert"; "begin"; "class"; "constraint"; "do"; "done"; "downto"; "else"; "end";
  "exception"; "extern"; "external"; "for"; "fun"; "function"; "functor"; "if"; "in"; "include"; 
  "inherit"; "inherit"; "initializer"; "lazy"; "let"; "match"; "method"; "method"; "module"; 
  "mutable"; "new"; "of"; "open"; "open"; "or"; "private"; "rec"; "sig"; "struct"; "then"; 
  "to"; "try"; "type"; "val"; "val"; "virtual"; "when"; "while"; "with";
]

let is_keyword = 
  let keywords = List.fold_right S.add keywords S.empty in
  fun s -> try S.find s keywords |> ignore; true
           with Not_found -> false

let jsoo_name name = (* XXX mangler *) 
  let name = if is_keyword name then name ^ "_" else name in
  let name = if String.contains name '_' then name ^ "_" else name in
  if name.[0] >= 'A' && name.[0] <= 'Z' then
    "_" ^ String.uncapitalize name
  else
    name

(* let find path name ast = (* XXX *) *)
let not_implemented out m = out m
let error = failwith

let type_ out t = 
  let not_implemented s = not_implemented out s in
  match t with
  | `PredefinedType p ->
      (match p with
      | `Any -> out "Ts.any"
      | `Number -> out "Ts.number"
      | `Boolean -> out "Ts.boolean"
      | `String -> out "Ts.string"
      | `Void -> out "Ts.void")
  | `TypeReference _ -> not_implemented "Ts.typeReference"
  | `TypeQuery _ -> not_implemented "Ts.typeQuery"
  | `TypeLiteral _ -> not_implemented "Ts.typeLiteral"

let type_opt out = function
  | None -> out "Ts.any"
  | Some(t) -> type_ out t

let propertySignature out psg = 
  out ("method " ^ jsoo_name psg.psg_propertyName ^ " : ");
  type_opt out psg.psg_typeAnnotation; 
  out " Js.prop\n"

let parameter_type param = 
  match param with
  | `RequiredParameter x -> x.rpr_typeAnnotation
  | `RequiredParameterSpecialized _ -> error "RequiredParameterSpecialized"
  | `OptionalParameter x -> x.opr_typeAnnotation
  | `OptionalParameterInit _ -> error "OptionalParameterInit"
  | `OptionalParameterSpecialized _ -> error "OptionalParameterSpecialized"
  | `RestParameter _ -> error "RestParamter"

let callSignature out csg = 
  assert (csg.csg_typeParameters = None);
  out "(";
  List.iter (fun p ->
    let t = parameter_type p in
    type_opt out t;
    out " -> "
  ) csg.csg_parameterList;
  type_opt out csg.csg_typeAnnotation;
  out ") Js.prop\n"

let methodSignature out mts = 
  out ("method " ^ jsoo_name mts.mts_propertyName ^ " : ");
  callSignature out mts.mts_callSignature

let interfaceDeclaration out idf = 
  let not_implemented = not_implemented out in
  assert (idf.idf_typeParameters = None);
  assert (idf.idf_interfaceExtendsClause = None);

  out ("class type " ^ jsoo_name idf.idf_identifier ^ " = object\n");
    
  List.iter (function
    | `PropertySignature psg -> propertySignature out psg
    | `CallSignature _ -> not_implemented "//CallSignature\n"
    | `ConstructSignature _ -> not_implemented "//ConstructSignature\n"
    | `IndexSignature _ -> not_implemented "//IndexSignature\n"
    | `MethodSignature mts -> methodSignature out mts
  ) idf.idf_objectType;

  out ("end\n")

let declarationElement out decl = 
  let not_implemented = not_implemented out in
  match decl with
  | `ExportAssignment name -> not_implemented "//ExportAssignment\n"
  | `InterfaceDeclaration idf -> interfaceDeclaration out idf
  | `ImportDeclaration idl -> not_implemented "//ImportDeclaration\n"
  | `ExternalImportDeclaration eid -> not_implemented "// ExternalImportDeclaration\n"
  | `AmbientDeclaration amb -> not_implemented "//AmbientDeclaration\n"


