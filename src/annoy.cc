#include "annoy_nifs.h"
#include "annoylib.h"
#include "kissrandom.h"

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


extern "C"
{
    ERL_NIF_TERM annoy_new_index(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_load(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_save(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_nns_by_item(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_nns_by_vector(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_item_vector(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_distance(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_n_items(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_get_n_trees(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    ERL_NIF_TERM annoy_add_item(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    
    void annoy_index_dtor(ErlNifEnv* env, void* arg);

    int on_load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info);
    
    static ErlNifFunc funcs[] =
    {
      {"new",               2, annoy_new_index,         0},
      {"load",              3, annoy_load,              0},
      {"save",              3, annoy_save,              0},
      {"get_nns_by_item",   5, annoy_get_nns_by_item,   0},
      {"get_nns_by_vector", 5, annoy_get_nns_by_vector, 0},
      {"get_item_vector",   2, annoy_get_item_vector,   0},
      {"get_distance",      3, annoy_get_distance,      0},
      {"get_n_items",       1, annoy_get_n_items,       0},
      {"get_n_trees",       1, annoy_get_n_trees,       0},
      {"add_item",          3, annoy_add_item,          0}
    };

    ERL_NIF_INIT(Elixir.AnnoyEx, funcs, &on_load, NULL, NULL, NULL)
};

bool ex_atom_to_bool(char *astr) {
  return strcmp(astr, "true") == 0;
}

bool check_constraints(ex_annoy *handle, int32_t item, bool building) {
  if (item < 0) {
    enif_fprintf(stderr, "Item index can not be negative");
    // PyErr_SetString(PyExc_IndexError, "Item index can not be negative");
    return false;
  } else if (!building && item >= handle->idx->get_n_items()) {
    enif_fprintf(stderr, "Item index larger than the largest item index");
    // PyErr_SetString(PyExc_IndexError, "Item index larger than the largest item index");
    return false;
  } else {
    return true;
  }
}

ERL_NIF_TERM annoy_new_index(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) 
{
  int f;
  char metric[16];
  
  if (!enif_get_int(env, argv[0], &f)) {
    return enif_make_badarg(env);
  }

  if(!enif_get_atom(env, argv[1], metric, sizeof(metric), ERL_NIF_LATIN1)) {
    return enif_make_badarg(env);
  }

  ex_annoy* handle = (ex_annoy*)enif_alloc_resource(ANNOY_INDEX_RESOURCE, sizeof(ex_annoy));
  handle->f = f;

  if(!strncmp(metric, "dot", sizeof(metric))) {
    handle->idx = new AnnoyIndex<int32_t, float, DotProduct, Kiss64Random, AnnoyIndexThreadedBuildPolicy>(f);
  } else if(!strncmp(metric, "euclidian", sizeof(metric))) {
    handle->idx = new AnnoyIndex<int32_t, float, Euclidean, Kiss64Random, AnnoyIndexThreadedBuildPolicy>(f);
  } else if(!strncmp(metric, "manhattan", sizeof(metric))) {
    handle->idx = new AnnoyIndexManhattan(f);
  } else {
    handle->idx = new AnnoyIndexAngular(f);
  }

  ERL_NIF_TERM result = enif_make_resource(env, handle);
  enif_release_resource(handle);
  
  return result;
}

ERL_NIF_TERM annoy_load(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    ex_annoy* handle;
    ErlNifBinary file;
    char prefault_arg[6];
    char *error;

    if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
         enif_inspect_binary(env, argv[1], &file) &&
         enif_get_atom(env, argv[2], prefault_arg, sizeof(prefault_arg), ERL_NIF_LATIN1))) {

        return enif_make_badarg(env);
    } else {
        enif_fprintf(stderr, "making filename from %s\n", file.data);
        const char *filename = reinterpret_cast<const char *>(file.data);
        enif_fprintf(stderr, "loading file %s\n", filename);
        bool prefault = ex_atom_to_bool(prefault_arg);

        if(!handle->idx->load(filename, prefault, &error)) {
          free(error);
          // TODO: use the error and return a tuple.
          return enif_make_atom(env, "err");
        }

        return enif_make_atom(env, "ok");
    }
}

ERL_NIF_TERM annoy_save(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    ex_annoy* handle;
    ErlNifBinary file;
    char prefault_arg[6];
    char *error;

    if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
         enif_inspect_binary(env, argv[1], &file) &&
         enif_get_atom(env, argv[2], prefault_arg, sizeof(prefault_arg), ERL_NIF_LATIN1))) {

        return enif_make_badarg(env);
    } else {
        char *filename = (char *)file.data;
        bool prefault = ex_atom_to_bool(prefault_arg);

        if(!handle->idx->save(filename, prefault, &error)) {
          free(error);
          // TODO: use the error and return a tuple.
          return enif_make_atom(env, "err");
        }

        return enif_make_atom(env, "ok");
    }
}

ERL_NIF_TERM annoy_get_nns_by_item(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  int32_t item, n, search_k, include_distances;
  char include_distances_arg[6];

  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
        enif_get_int(env, argv[1], &item) &&
        enif_get_int(env, argv[2], &n),
        enif_get_int(env, argv[3], &search_k),
        enif_get_atom(env, argv[4], include_distances_arg, sizeof(include_distances_arg), ERL_NIF_LATIN1))) {

      return enif_make_badarg(env);
  }

  include_distances = !strcmp("include_distances_arg", "false") ? 0 : 1; 

  if(!check_constraints(handle, item, false)) {
    // TODO: return :err, errstring.
    return enif_make_badarg(env);
  }

  vector<int32_t> result;
  vector<float> distances;
  ERL_NIF_TERM result_list = enif_make_list(env, 0);
  ERL_NIF_TERM distances_list = enif_make_list(env, 0);

  enif_fprintf(stderr, "getting nns_by_item\n");
  handle->idx->get_nns_by_item(item, n, search_k, &result, include_distances ? &distances : NULL);
  
  if(result.size()) {
    enif_fprintf(stderr, "making list from result\n");
    for (auto i = result.begin(); i != result.end(); ++i)
      result_list = enif_make_list_cell(env, enif_make_int(env, *i), result_list);
  }

  if(distances.size()) {
    enif_fprintf(stderr, "making distances from result\n");
    for (auto i = distances.begin(); i != distances.end(); ++i)
      distances_list = enif_make_list_cell(env, enif_make_double(env, *i), distances_list);
  }
  
  return enif_make_tuple2(env, result_list, distances_list);
}

ERL_NIF_TERM annoy_get_nns_by_vector(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  // the vector to search by.
  const ERL_NIF_TERM *v;
  int32_t arity, n, search_k, include_distances;
  char include_distances_arg[6];

  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
        enif_get_tuple(env, argv[1], &arity, &v) &&
        enif_get_int(env, argv[2], &n),
        enif_get_int(env, argv[3], &search_k),
        enif_get_atom(env, argv[4], include_distances_arg, sizeof(include_distances_arg), ERL_NIF_LATIN1))) {

      return enif_make_badarg(env);
  }

  include_distances = !strcmp("include_distances_arg", "false") ? 0 : 1; 

  vector<int32_t> result;
  vector<float> distances;
  ERL_NIF_TERM result_list = enif_make_list(env, 0);
  ERL_NIF_TERM distances_list = enif_make_list(env, 0);

  if(handle->f != arity) {
    enif_fprintf(stderr, "Vector has wrong length (expected %d, got %d)\n", handle->f, arity);
    return enif_make_badarg(env);
  }

  // vector to search for.
  vector<float> w(handle->f);
  for(int i=0; i<arity; i++) {
    double d;
    if(enif_get_double(env, v[i], &d)) {
      w.push_back((float)d);
    }
  }  
  enif_fprintf(stderr, "getting nns_by_vector\n");
  handle->idx->get_nns_by_vector(&w[0], n, search_k, &result, include_distances ? &distances : NULL);
  
  if(result.size()) {
    enif_fprintf(stderr, "making list from result\n");
    for (auto i = result.begin(); i != result.end(); ++i)
      result_list = enif_make_list_cell(env, enif_make_int(env, *i), result_list);
  }

  if(distances.size()) {
    enif_fprintf(stderr, "making distances from result\n");
    for (auto i = distances.begin(); i != distances.end(); ++i)
      distances_list = enif_make_list_cell(env, enif_make_double(env, *i), distances_list);
  }
  
  return enif_make_tuple2(env, result_list, distances_list);
}

// TODO: comes back in reverse order.
ERL_NIF_TERM annoy_get_item_vector(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ex_annoy* handle;
  int32_t item;
  ERL_NIF_TERM list = enif_make_list(env, 0);

  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &item))) {
    
    return enif_make_badarg(env);
  }

  if(!check_constraints(handle, item, false)) {
    // TODO: return :err, errstring.
    return enif_make_badarg(env);
  }

  vector<float> v(handle->f);
  handle->idx->get_item(item, &v[0]);

  for(int i=0; i < handle->f; i++) {
    list = enif_make_list_cell(env, enif_make_double(env, v[i]), list);
  }

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
  const ERL_NIF_TERM *v;
  int32_t item, arity;

  if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
       enif_get_int(env, argv[1], &item) &&
       enif_get_tuple(env, argv[2], &arity, &v))) {
    
    return enif_make_badarg(env);
  }

  if(!check_constraints(handle, item, true)) {
    // TODO: return :err, errstring.
    return enif_make_badarg(env);
  }

  vector<float> w(handle->f);
  for(int i=0; i<arity; i++) {
    double d;
    if(enif_get_double(env, (ERL_NIF_TERM)v[i], &d)) {
      w.push_back((float)d);
    }
  }

  char *error;
  if(!handle->idx->add_item(item, &w[0], &error)) {
    enif_fprintf(stderr, "problem adding: %s\n", error);
    free(error);

    return enif_make_atom(env, "err");
  }
  
  return enif_make_atom(env, "ok");
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
                                                    
    return 0;
}