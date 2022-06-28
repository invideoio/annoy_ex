#include "annoy_nifs.h"
#include "annoylib.h"
#include "kissrandom.h"
#include <string>

using namespace Annoy;

#ifdef ANNOYLIB_MULTITHREADED_BUILD
  typedef AnnoyIndexMultiThreadedBuildPolicy AnnoyIndexThreadedBuildPolicy;
#else
  typedef AnnoyIndexSingleThreadedBuildPolicy AnnoyIndexThreadedBuildPolicy;
#endif

template class AnnoyIndexInterface<int32_t, float>;

typedef AnnoyIndex<int32_t, float, Angular, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexAngular;
typedef AnnoyIndex<int32_t, float, DotProduct, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexDotProduct;
typedef AnnoyIndex<int32_t, float, Euclidean, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexEuclidean;
typedef AnnoyIndex<int32_t, float, Manhattan, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexManhattan;

static ErlNifResourceType* ANNOY_INDEX_RESOURCE;

typedef struct
{
  // number of dimensions.
  int f;
  // the Annoy index instance.
   AnnoyIndexInterface<int32_t, float>* idx;
} ex_annoy;

struct atoms
{
  ERL_NIF_TERM a_ok;
  ERL_NIF_TERM a_err;
  ERL_NIF_TERM a_true;
  ERL_NIF_TERM a_false;
  ERL_NIF_TERM a_euclidean;
  ERL_NIF_TERM a_manhattan;
  ERL_NIF_TERM a_dot;
  ERL_NIF_TERM a_angular;
};

static atoms ATOMS;

extern "C"
{
    ERL_NIF_TERM annoy_new_index(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_add_item(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_build(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_unbuild(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_save(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_load(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_unload(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);  
    ERL_NIF_TERM annoy_get_nns_by_item(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_nns_by_vector(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_item_vector(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_distance(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_n_items(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_n_trees(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_on_disk_build(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_verbose(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_set_seed(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);  
  
    void annoy_index_dtor(ErlNifEnv* env, void* arg);

    int on_load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info);
    
    static ErlNifFunc funcs[] =
    {
      {"new",               2, annoy_new_index,         0},
      {"add_item",          3, annoy_add_item,          0},
      {"build",             3, annoy_build,             0},
      {"unbuild",           1, annoy_unbuild,           0},
      {"save",              3, annoy_save,              0},
      {"load",              3, annoy_load,              0},
      {"unload",            1, annoy_unload,            0},
      {"get_nns_by_item",   5, annoy_get_nns_by_item,   0},
      {"get_nns_by_vector", 5, annoy_get_nns_by_vector, 0},
      {"get_item_vector",   2, annoy_get_item_vector,   0},
      {"get_distance",      3, annoy_get_distance,      0},
      {"get_n_items",       1, annoy_get_n_items,       0},
      {"get_n_trees",       1, annoy_get_n_trees,       0},
      {"on_disk_build",     2, annoy_on_disk_build,     0},
      {"verbose",           2, annoy_verbose,           0},
      {"set_seed",          2, annoy_set_seed,          0},
    };

    ERL_NIF_INIT(Elixir.AnnoyEx, funcs, &on_load, NULL, NULL, NULL)
};

bool get_boolean(ERL_NIF_TERM term, bool* val) {
  if(enif_is_identical(term, ATOMS.a_true)) {
    *val = true;
    return true;
  }

  if(enif_is_identical(term, ATOMS.a_false)) {
    *val = false;
    return true;
  }

  return false;
}

bool get_binary(ErlNifEnv* env, ERL_NIF_TERM term, ErlNifBinary* bin)
{
    if(enif_is_binary(env, term))
        return enif_inspect_binary(env, term, bin);

    return enif_inspect_iolist_as_binary(env, term, bin);
}

bool get_string(ErlNifEnv *env, ERL_NIF_TERM term, std::string* var)
{
    ErlNifBinary bin;

    if(get_binary(env, term, &bin))
    {
        *var = std::string(reinterpret_cast<const char*>(bin.data), bin.size);
        return true;
    }

    return false;
}

// populate d with the double form of item - return true if it
// can convert or false if it can not.
bool get_vector_item(ErlNifEnv *env, ERL_NIF_TERM item, double* d) {
  int i;

  if(!enif_is_number(env, item)) {
    return false;
  }
  
  if(enif_get_double(env, item, d)) {
    // d has the value
  } else if(enif_get_int(env, item, &i)) {
    *d = i * 1.0;
  } else {
    return false;
  }

  return true;
}

ERL_NIF_TERM make_atom(ErlNifEnv* env, const char* name)
{
    ERL_NIF_TERM ret;

    if(enif_make_existing_atom(env, name, &ret, ERL_NIF_LATIN1))
        return ret;

    return enif_make_atom(env, name);
}

ERL_NIF_TERM error_tuple(ErlNifEnv* env, const char* name)
{
  return enif_make_tuple2(env, ATOMS.a_err, enif_make_string(env, name, ERL_NIF_LATIN1));
}

bool check_constraints(ex_annoy *handle, int32_t item, bool building) {
  if (item < 0) {
    enif_fprintf(stderr, "Item index can not be negative");
    return false;
  } else if (!building && item >= handle->idx->get_n_items()) {
    enif_fprintf(stderr, "Item index larger than the largest item index");
    return false;
  } else {
    return true;
  }
}

ERL_NIF_TERM
nns_to_ex(ErlNifEnv *env, const vector<int32_t>& result, const vector<float>& distances, int include_distances) {
  ERL_NIF_TERM l = enif_make_list(env, 0);
  ERL_NIF_TERM d = enif_make_list(env, 0);

  for(size_t i = 0; i < result.size(); i++)
    l = enif_make_list_cell(env, enif_make_int(env, result[i]), l);
  
  enif_make_reverse_list(env, l, &l);

  if(include_distances) {
    for(size_t i = 0; i < distances.size(); i++)
      d = enif_make_list_cell(env, enif_make_double(env, distances[i]), d);
  
    enif_make_reverse_list(env, d, &d);
  }

  return enif_make_tuple2(env, l, d);
}  

ERL_NIF_TERM annoy_new_index(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) 
{
  int f;
  
  if (!enif_get_int(env, argv[0], &f))
    return enif_make_badarg(env);

  if(!enif_is_atom(env, argv[1]))
    return enif_make_badarg(env);

  ex_annoy* handle = (ex_annoy*)enif_alloc_resource(ANNOY_INDEX_RESOURCE, sizeof(ex_annoy));
  handle->f = f;

  if(enif_is_identical(argv[1], ATOMS.a_dot)) {
    handle->idx = new AnnoyIndexDotProduct(f);
  } else if(enif_is_identical(argv[1], ATOMS.a_euclidean)) {
    handle->idx = new AnnoyIndexEuclidean(f);
  } else if(enif_is_identical(argv[1], ATOMS.a_manhattan)) {
    handle->idx = new AnnoyIndexManhattan(f);
  } else if(enif_is_identical(argv[1], ATOMS.a_angular)) {
    handle->idx = new AnnoyIndexAngular(f);
  } else {
    return enif_make_badarg(env);
  }

  ERL_NIF_TERM result = enif_make_resource(env, handle);
  enif_release_resource(handle);
  
  return result;
}

ERL_NIF_TERM annoy_load(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    ex_annoy* handle;
    std::string file;
    bool prefault;
    char *error;
    ERL_NIF_TERM ret = ATOMS.a_ok;

    if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
         get_string(env, argv[1], &file) &&
         get_boolean(argv[2], &prefault))) {

      return enif_make_badarg(env);
    } else {
      if(!handle->idx->load(file.c_str(), prefault, &error)) {
        ret = error_tuple(env, error); 
        free(error);
      }

      return ret;
    }
}

ERL_NIF_TERM annoy_save(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    ex_annoy* handle;
    std::string file;
    bool prefault;
    char *error;
    ERL_NIF_TERM ret = ATOMS.a_ok;
    
    if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
         get_string(env, argv[1], &file) && 
         get_boolean(argv[2], &prefault))) {

      return enif_make_badarg(env);
    } else {
      if(!handle->idx->save(file.c_str(), prefault, &error)) {
        ret = error_tuple(env, error); 
        free(error);
      }
 
      return ret;
    }
}

ERL_NIF_TERM annoy_get_nns_by_item(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  int32_t item, n, search_k;
  bool include_distances;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &item) &&
       enif_get_int(env, argv[2], &n) &&
       enif_get_int(env, argv[3], &search_k) &&
       get_boolean(argv[4], &include_distances))) {

    return enif_make_badarg(env);
  }

  if(!check_constraints(handle, item, false))
    return enif_make_badarg(env);

  // the results from the annoy function.
  vector<int32_t> result;
  vector<float> distances;

  handle->idx->get_nns_by_item(item, n, search_k, &result, include_distances ? &distances : NULL);

  return nns_to_ex(env, result, distances, include_distances);
}

ERL_NIF_TERM annoy_get_nns_by_vector(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  // the vector to search by and item from it.
  ERL_NIF_TERM v, item;
  unsigned int arity;
  int32_t n, search_k;
  bool include_distances;

  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_list_length(env, argv[1], &arity) &&
       enif_get_int(env, argv[2], &n) &&
       enif_get_int(env, argv[3], &search_k) &&
       get_boolean(argv[4], &include_distances))) {

    return enif_make_badarg(env);
  }

  if((unsigned)handle->f != arity) {
    enif_fprintf(stderr, "Vector has wrong length (expected %d, got %d)\n", handle->f, arity);
    return enif_make_badarg(env);
  }

  // vector to search for.
  vector<float> w(handle->f);
  v = argv[1];

  for(unsigned int i=0; i<arity; i++) {
    double d;

    if(!enif_get_list_cell(env, v, &item, &v)) {
      enif_fprintf(stderr, "Could not get list item.\n");
      return enif_make_badarg(env);
    }
    
    bool ret = get_vector_item(env, item, &d);
    if(!ret) {
      enif_fprintf(stderr, "Could not convert vector item to double.\n");
      return enif_make_badarg(env);
    }

    w[i] = d;
  }

  vector<int32_t> result;
  vector<float> distances;
  
  handle->idx->get_nns_by_vector(&w[0], n, search_k, &result, include_distances ? &distances : NULL);

  return nns_to_ex(env, result, distances, include_distances);  
}

ERL_NIF_TERM annoy_get_item_vector(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  int32_t item;
  ERL_NIF_TERM list = enif_make_list(env, 0);

  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &item))) {
    
    return enif_make_badarg(env);
  }

  if(!check_constraints(handle, item, false))
    return enif_make_badarg(env);

  vector<float> v(handle->f);
  handle->idx->get_item(item, &v[0]);

  for(int i=0; i < handle->f; i++) {
    list = enif_make_list_cell(env, enif_make_double(env, v[i]), list);
  }

  enif_make_reverse_list(env, list, &list);

  return list;
}

ERL_NIF_TERM annoy_get_distance(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  int32_t i, j;

  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &i) &&
       enif_get_int(env, argv[2], &j))) {
    
    return enif_make_badarg(env);
  }

  if (!check_constraints(handle, i, false) || !check_constraints(handle, j, false))
    return enif_make_badarg(env);

  double d = handle->idx->get_distance(i,j);

  return enif_make_double(env, d);
}

ERL_NIF_TERM annoy_get_n_items(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;

  if(!enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle)) {
    return enif_make_badarg(env);
  }

  return enif_make_int(env, handle->idx->get_n_items());
}

ERL_NIF_TERM annoy_get_n_trees(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;

  if(!enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle)) {
    return enif_make_badarg(env);
  }

  return enif_make_int(env, handle->idx->get_n_trees());
}

ERL_NIF_TERM annoy_add_item(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  // the vector to add and item with in it.
  ERL_NIF_TERM v, item;
  // size of the list passed in.
  unsigned int arity;
  // position to add the vector to
  int32_t pos;
  ERL_NIF_TERM ret = ATOMS.a_ok;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &pos) &&
       enif_get_list_length(env, argv[2], &arity))) {
    
    return enif_make_badarg(env);
  }

  if(!check_constraints(handle, pos, true))
    return enif_make_badarg(env);

  vector<float> w(handle->f);
  v = argv[2];
  double d;

  for(unsigned int i=0; i<arity; i++) {
    if(!enif_get_list_cell(env, v, &item, &v)) {
      enif_fprintf(stderr, "Could not get list item.\n");
      return enif_make_badarg(env);
    }

    if(!get_vector_item(env, item, &d)) {
      enif_fprintf(stderr, "failed to convert item %d to int or double\n", i);
      return enif_make_badarg(env);
    }

    w[i] = d;
  }

  char *error;
  if(!handle->idx->add_item(pos, &w[0], &error)) {
    ret = error_tuple(env, error);
    free(error);
  }

  return ret;
}

void annoy_index_dtor(ErlNifEnv* env, void* arg)
{
    ex_annoy* handle = (ex_annoy*)arg;
    delete handle->idx;
}

int on_load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info)
{
    ErlNifResourceFlags flags = (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);
    ANNOY_INDEX_RESOURCE = enif_open_resource_type(env, "Elixir.AnnoyEx", "annoy_index_resource", &annoy_index_dtor, flags, 0);

    ATOMS.a_ok = make_atom(env, "ok");
    ATOMS.a_err = make_atom(env, "err");
    ATOMS.a_true = make_atom(env, "true");
    ATOMS.a_false = make_atom(env, "false");
    ATOMS.a_euclidean = make_atom(env, "euclidean");
    ATOMS.a_manhattan = make_atom(env, "manhattan");
    ATOMS.a_dot = make_atom(env, "dot");
    ATOMS.a_angular = make_atom(env, "angular");
    
    return 0;
}

ERL_NIF_TERM annoy_build(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  int32_t n_trees, n_jobs;
  char *error;
  ERL_NIF_TERM ret = ATOMS.a_ok;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &n_trees) &&
       enif_get_int(env, argv[2], &n_jobs))) {
    
    return enif_make_badarg(env);
  }

  bool res = handle->idx->build(n_trees, n_jobs, &error);

  if(!res) {
    ret = error_tuple(env, error);
    free(error);
  }
  
  return ret;
}

ERL_NIF_TERM annoy_unbuild(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  char *error;
  ERL_NIF_TERM ret = ATOMS.a_ok;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle))) {
    return enif_make_badarg(env);
  }

  if(!handle->idx->unbuild(&error)) {
    ret = error_tuple(env, error);
    free(error);
  }
  
  return ret;
}

ERL_NIF_TERM annoy_unload(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle))) {
    return enif_make_badarg(env);
  }
  
  handle->idx->unload();

  return ATOMS.a_ok;
}

ERL_NIF_TERM annoy_verbose(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  bool verbose;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle)) &&
     get_boolean(argv[1], &verbose)) {
    return enif_make_badarg(env);
  }

  handle->idx->verbose(verbose);

  return ATOMS.a_ok;
}

ERL_NIF_TERM annoy_set_seed(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  int q;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &q))) { 
    return enif_make_badarg(env);
  }
  
  handle->idx->set_seed(q);

  return ATOMS.a_ok;
}

ERL_NIF_TERM annoy_on_disk_build(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  std::string file;
  char *error;
  ERL_NIF_TERM ret = ATOMS.a_ok;
  
  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       get_string(env, argv[1], &file))) { 
    return enif_make_badarg(env);
  }

  if(!handle->idx->on_disk_build(file.c_str(), &error)) {
    ret = error_tuple(env, error);
    free(error);
  }

  return ret;
}
