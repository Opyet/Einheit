import React from 'react';
import { BrowserRouter as Router, Switch, Route, Redirect } from 'react-router-dom';
import logo from './logo.svg';
import { Counter } from './features/counter/Counter';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        
      </header>
      <Router>
        <Switch>
          <Route exact path="/" component={Swap} />
          <Route exact path="/stake" component={Stake} />
          <Route exact path="/world" component={Analytics} />
          <Route path="*">
            {account ? <Redirect to="/" /> : <Redirect to="/world" />}
          </Route>
        </Switch>
      </Router>
    </div>
  );
}

export default App;
