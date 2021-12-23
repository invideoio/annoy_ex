#include "annoylib.h"
#include "kissrandom.h"
#include <erl_nif.h>

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
   AnnoyIndexInterface<int32_t, float>* idx;
} ex_annoy;

bool ex_atom_to_bool(char *astr) {
  return strcmp(astr, "true") == 0;
}

bool check_constraints(ex_annoy *handle, int32_t item, bool building) {
  if (item < 0) {
    // PyErr_SetString(PyExc_IndexError, "Item index can not be negative");
    return false;
  } else if (!building && item >= handle->idx->get_n_items()) {
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
    // char filename[4096];
    char *error;

    // (void)memset(&filename, '\0', sizeof(filename));

    if(!(enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&handle) &&
         enif_inspect_binary(env, argv[1], &file) &&
         // enif_get_string(env, argv[1], filename, sizeof(filename), ERL_NIF_LATIN1) &&
         enif_get_atom(env, argv[2], prefault_arg, sizeof(prefault_arg), ERL_NIF_LATIN1))) {

        return enif_make_badarg(env);
    } else {
        const char *filename = reinterpret_cast<const char *>(file.data);
        // enif_get_string(env, argv[1], filename, sizeof(filename), ERL_NIF_LATIN1);
        bool prefault = ex_atom_to_bool(prefault_arg);

        //enif_fprintf(stderr, "loading %s\n", filename);
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

        // enif_fprintf(stderr, "loading %s", filename);
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

static ErlNifFunc funcs[] =
{
  {"new",             2, annoy_new_index,       0},
  {"load",            3, annoy_load,            0},
  {"save",            3, annoy_save,            0},
  {"get_nns_by_item", 5, annoy_get_nns_by_item, 0}
};

ERL_NIF_INIT(Elixir.AnnoyEx, funcs, &on_load, NULL, NULL, NULL)