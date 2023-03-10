import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:imdb/bloc/movie_bloc.dart';
import 'package:imdb/movie_models/movie.dart';
import 'package:imdb/screens/movie_screen.dart';
import 'package:imdb/screens/tvcast_screen.dart';
import 'package:imdb/widgets/tvshow_widget.dart';

class TVShowScreen extends StatefulWidget {
  const TVShowScreen({Key? key}) : super(key: key);

  @override
  _TVShowScreenState createState() => _TVShowScreenState();
}

class _TVShowScreenState extends State<TVShowScreen> {

  List<TVShow> finalTVShowList = [];
  List<String> searchHistory = [];

  @override
  void initState() {
    super.initState();
    getSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<MovieBloc>(context).add(Top250TVs());
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Top 250 TV Series",
          style: TextStyle(
              color: Colors.white
          ),
        ),
        actions: [
          IconButton(
              onPressed: (){
                showSearch(
                    context: context,
                    delegate: TVsearchDelegate(searchHistory: searchHistory, updateBox: updateBox)
                );
              },
              icon: const Icon(Icons.search)
          )
        ],
      ),
      drawer: Drawer(
          child: Material(
            child: ListView(
              children: [
                ListTile(
                    tileColor: Colors.amber,
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.black,
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                    )
                ),
                Container(
                  color: Colors.amber,
                  child: const Align(
                    alignment: Alignment.bottomCenter,
                    child: DrawerHeader(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          "imDb",
                          style: TextStyle(
                              fontSize: 48,
                              color: Colors.black,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),

                    ),
                  ),
                ),
                const Divider(
                  color: Colors.white54,
                ),
                ListTile(
                  title: const Center(
                    child: Text(
                      "Movies",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                  onTap: (){
                    selectedItem(context, 0);
                  },
                ),
                ListTile(
                  title: const Center(
                    child: Text(
                      "TV Series",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                  selected: true,
                  onTap: (){
                    selectedItem(context, 1);
                  },
                )
              ],
            ),
          )
      ),
      body: BlocConsumer<MovieBloc, MovieState>(
        builder: (context, state){
          if(state is Fetching){
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          else if(state is TVShowsFetched){
            finalTVShowList = state.shows;
            return TVShowWidget(
                shows: state.shows
            );
          }
          else if(state is Reloaded){
            return TVShowWidget(
                shows: finalTVShowList
            );
          }
          else if(state is TVShowCastFetched){
            SchedulerBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) {
                        BlocProvider.of<MovieBloc>(context).add(Reload());
                        return TVShowCastScreen(showCast: state.showcast);
                      }
                  )
              );
            });
            return Container();
          }
          else if(state is MoviesError)
          {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Oops, something went wrong",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey
                  ),
                )
              ],
            );
          }
          else
            {
              return Container();
            }
        },
        listener: (context, state){
        },
      ),
    );
  }

  void selectedItem(BuildContext context, int i)
  {
    switch(i)
    {
      case 1:
        Navigator.of(context).pop();
        break;
      case 0:
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) {
                    //BlocProvider.of<MovieBloc>(context).add(Top250TVs());
                    return const MovieScreen();
                  }
              )
          );
        });
        break;
    }
  }

  void getSearchHistory() async{
    try{
      var box = await Hive.openBox('showSearchList');

      List<String> searchList = box.get('searched', defaultValue: []);
      searchHistory = searchList;
    }
    catch(e){
    }
  }

  void updateBox(List<String> newList) async{
    var box = await Hive.openBox('showSearchList');
    await box.put('searched', newList);

  }

}

class TVsearchDelegate extends SearchDelegate{

  final List<String> searchHistory;
  final Function updateBox;

  TVsearchDelegate({required this.searchHistory, required this.updateBox});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: ()
        {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: (){
          BlocProvider.of<MovieBloc>(context).add(Top250TVs());
          close(context, null);
        },
        icon: const Icon(Icons.arrow_back)
    );
  }

  @override
  Widget buildResults(BuildContext context) {

    if(!searchHistory.contains(query) && query.isNotEmpty){
      searchHistory.add(query);
      this.updateBox(searchHistory);
    }

    BlocProvider.of<MovieBloc>(context).add(
        SearchTVs(query)
    );

    return WillPopScope(
      onWillPop: () async{

        BlocProvider.of<MovieBloc>(context).add(Top250TVs());
        close(context, null);
        return await Future.delayed(const Duration(milliseconds: 1));
      },
      child: BlocConsumer<MovieBloc, MovieState>(
        builder: (context, state){
          if(state is Fetching){
            return const Center(child: CircularProgressIndicator());
          }
          else if(state is TVShowsFetched) {
            List<TVShow> shows = state.shows;
            return TVShowWidget(shows: shows);
          }

          return const Text("");
        },
        listener: (context, state){
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];

    for(var term in searchHistory){
      if(query.isEmpty){
        matchQuery.add(term);
      }
      else if(term.toLowerCase().contains(query.toLowerCase())){
        matchQuery.add(term);
      }
    }

    return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, i){
          return ListTile(
            title: Text(
                matchQuery[i],
                style: TextStyle(color: Colors.grey)
            ),
            onTap: (){
              query = matchQuery[i];
            },
          );
        }
    );
  }

}
